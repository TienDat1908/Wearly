class BookingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @bookings = current_user
      .rentals
      .includes(:owner, product: [photos_attachments: :blob])
      .order(created_at: :desc)

    @bookings.pending.find_each(&:expire_if_acceptance_timed_out!)
    @bookings = @bookings.reload
  end

  def show
    @booking = current_user
      .rentals
      .includes(:owner, product: [photos_attachments: :blob])
      .find(params[:id])
    @booking.expire_if_acceptance_timed_out!
  end

  def new
    @product = Product.active.includes(owner: { avatar_attachment: :blob }).find(params[:product_id])

    if @product.owner_id == current_user.id
      redirect_to product_path(@product), alert: t("flash.bookings.cannot_rent_own_product")
      return
    end

    @booking = Booking.new
    from = Date.current.beginning_of_month
    to = (Date.current + 2.months).end_of_month
    @busy = Products::BusyRanges.call(product: @product, from: from, to: to).busy
  end

  def create
    @product = Product.active.find(booking_params[:product_id])

    if @product.owner_id == current_user.id
      redirect_to product_path(@product), alert: t("flash.bookings.cannot_rent_own_product")
      return
    end

    booking_address =
      if booking_params[:pickup_method] == "self_pickup"
        @product.pickup_location
      else
        booking_params[:pickup_address]
      end

    @booking = Booking.new(
      product: @product,
      owner: @product.owner,
      renter: current_user,
      start_time: booking_params[:start_time],
      end_time: booking_params[:end_time],
      pickup_method: booking_params[:pickup_method],
      pickup_address: booking_address,
      return_address: booking_address
    )

    unless @booking.valid?
      render :new, status: :unprocessable_entity
      return
    end

    unless @product.available_for?(@booking.start_time, @booking.end_time)
      @booking.errors.add(:base, t("flash.bookings.unavailable"))
      render :new, status: :unprocessable_entity
      return
    end

    price = Booking.price_breakdown(
      product: @product,
      start_time: @booking.start_time,
      end_time: @booking.end_time
    )

    @booking.assign_attributes(
      rental_days: price[:rental_days],
      rental_amount: price[:rental_amount],
      cleaning_fee: price[:cleaning_fee],
      deposit_amount: price[:deposit_amount],
      platform_fee_rate: price[:platform_fee_rate],
      platform_fee_amount: price[:platform_fee_amount],
      renter_service_fee_rate: price[:renter_service_fee_rate],
      renter_service_fee_amount: price[:renter_service_fee_amount],
      owner_earning_amount: price[:owner_earning_amount],
      total_amount: price[:total_amount]
    )

    @product.with_lock do
      unless @product.available_for?(@booking.start_time, @booking.end_time)
        @booking.errors.add(:base, t("flash.bookings.unavailable"))
        raise ActiveRecord::Rollback
      end

      @booking.save!
      @booking.create_product_reservation!(
        product: @product,
        renter: current_user,
        start_time: @booking.start_time,
        end_time: @booking.end_time,
        status: "pending",
        reason: "booking"
      )
      Conversations::EnsureBooking.call(booking: @booking)
    end

    unless @booking.persisted?
      render :new, status: :unprocessable_entity
      return
    end

    redirect_to booking_path(@booking), notice: t("flash.bookings.created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def cancel
    @booking = current_user.rentals.find(params[:id])

    unless @booking.pending? || @booking.accepted?
      redirect_to booking_path(@booking), alert: t("flash.bookings.invalid_status")
      return
    end

    ActiveRecord::Base.transaction do
      @booking.cancel!
      @booking.update!(cancelled_at: Time.current)
      @booking.product_reservation&.update!(status: "cancelled")
    end

    redirect_to booking_path(@booking), notice: t("flash.bookings.cancelled")
  end

  def pay
    @booking = current_user.rentals.find(params[:id])

    unless @booking.accepted?
      redirect_to booking_path(@booking), alert: t("flash.bookings.invalid_status")
      return
    end

    ActiveRecord::Base.transaction do
      payment = @booking.payment || @booking.build_payment

      payment.update!(
        payer_id: current_user.id,
        amount: @booking.total_amount.to_i,
        payment_method: "manual",
        status: "paid",
        transaction_id: "MANUAL-#{SecureRandom.hex(8).upcase}",
        paid_at: Time.current
      )

      @booking.pay!
    end

    redirect_to booking_path(@booking), notice: t("flash.bookings.paid")
  end

  def confirm_received
    @booking = current_user.rentals.find(params[:id])

    unless @booking.paid? && @booking.paid_successfully?
      redirect_to booking_path(@booking), alert: t("flash.bookings.invalid_status")
      return
    end

    ActiveRecord::Base.transaction do
      @booking.confirm_pickup!
      @booking.update!(picked_up_at: Time.current)
    end

    redirect_to booking_path(@booking), notice: t("flash.bookings.received")
  end

  def chat
    @booking = current_user.rentals.find(params[:id])
    open_booking_chat!(@booking)
  end

  private

  def open_booking_chat!(booking)
    unless booking.chattable?
      redirect_to booking_path(booking), alert: t("flash.conversations.booking_chat_unavailable")
      return
    end

    conversation = Conversations::EnsureBooking.call(booking: booking)
    redirect_to conversation_path(conversation)
  end

  def booking_params
    params.require(:booking).permit(
      :product_id,
      :start_time,
      :end_time,
      :pickup_method,
      :pickup_address
    )
  end

end
