class BookingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @bookings = current_user.rentals.includes(:product).order(created_at: :desc)
  end

  def show
    @booking = current_user.rentals.find(params[:id])
  end

  def new
    @product = Product.active.find(params[:product_id])

    if @product.owner_id == current_user.id
      redirect_to product_path(@product), alert: t("flash.bookings.cannot_rent_own_product")
      return
    end

    @booking = Booking.new
  end

  def create
    @product = Product.active.find(booking_params[:product_id])

    if @product.owner_id == current_user.id
      redirect_to product_path(@product), alert: t("flash.bookings.cannot_rent_own_product")
      return
    end

    start_time = Time.zone.parse(booking_params[:start_time])
    end_time = Time.zone.parse(booking_params[:end_time])

    unless @product.available_for?(start_time, end_time)
      redirect_to product_path(@product), alert: t("flash.bookings.unavailable")
      return
    end

    price = calculate_price(@product, start_time, end_time)

    @booking = Booking.new(
      product: @product,
      owner: @product.owner,
      renter: current_user,
      start_time: start_time,
      end_time: end_time,
      rental_days: price[:rental_days],
      rental_amount: price[:rental_amount],
      cleaning_fee: price[:cleaning_fee],
      deposit_amount: price[:deposit_amount],
      platform_fee_rate: price[:platform_fee_rate],
      platform_fee_amount: price[:platform_fee_amount],
      renter_service_fee_rate: price[:renter_service_fee_rate],
      renter_service_fee_amount: price[:renter_service_fee_amount],
      owner_earning_amount: price[:owner_earning_amount],
      total_amount: price[:total_amount],
      pickup_method: booking_params[:pickup_method],
      pickup_address: booking_params[:pickup_address],
      return_address: booking_params[:return_address]
    )

    ActiveRecord::Base.transaction do
      @booking.save!

      ProductReservation.create!(
        product: @product,
        booking: @booking,
        renter: current_user,
        start_time: start_time,
        end_time: end_time,
        status: "pending",
        reason: "booking"
      )
    end

    redirect_to booking_path(@booking), notice: t("flash.bookings.created")
  rescue ActiveRecord::RecordInvalid, ArgumentError
    redirect_to product_path(@product), alert: t("flash.bookings.failed")
  end

  def cancel
    @booking = current_user.rentals.find(params[:id])

    unless @booking.pending? || @booking.accepted?
      redirect_to booking_path(@booking), alert: t("flash.bookings.invalid_status")
      return
    end

    ActiveRecord::Base.transaction do
      @booking.cancel!
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

  private

  def booking_params
    params.require(:booking).permit(
      :product_id,
      :start_time,
      :end_time,
      :pickup_method,
      :pickup_address,
      :return_address
    )
  end

  def calculate_price(product, start_time, end_time)
    rental_days = [(end_time.to_date - start_time.to_date).to_i + 1, 1].max

    rental_amount = product.price_per_day.to_i * rental_days
    cleaning_fee = product.cleaning_fee.to_i
    deposit_amount = product.deposit_amount.to_i

    platform_fee_rate = Booking::OWNER_PLATFORM_FEE_RATE
    renter_service_fee_rate = Booking::RENTER_SERVICE_FEE_RATE

    platform_fee_amount = (rental_amount * platform_fee_rate / 100.0).round
    renter_service_fee_amount = (rental_amount * renter_service_fee_rate / 100.0).round

    owner_earning_amount = rental_amount + cleaning_fee - platform_fee_amount

    total_amount =
      rental_amount +
      cleaning_fee +
      deposit_amount +
      renter_service_fee_amount

    {
      rental_days: rental_days,
      rental_amount: rental_amount,
      cleaning_fee: cleaning_fee,
      deposit_amount: deposit_amount,
      platform_fee_rate: platform_fee_rate,
      platform_fee_amount: platform_fee_amount,
      renter_service_fee_rate: renter_service_fee_rate,
      renter_service_fee_amount: renter_service_fee_amount,
      owner_earning_amount: owner_earning_amount,
      total_amount: total_amount
    }
  end
end