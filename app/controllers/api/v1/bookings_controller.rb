module Api
  module V1
    class BookingsController < BaseController
      before_action :authenticate_api_user!

      def index
        bookings = current_api_user
          .rentals
          .includes(:owner, :payment, :renter, product: [photos_attachments: :blob])
          .order(created_at: :desc)

        bookings.find_each(&:expire_if_acceptance_timed_out!)

        render json: {
          bookings: bookings.reload.map { |booking| BookingSerializer.new(booking, request: request, viewer: current_api_user).as_json }
        }
      end

      def show
        booking = current_api_user
          .rentals
          .includes(:owner, :payment, :renter, product: [photos_attachments: :blob])
          .find(params[:id])
        booking.expire_if_acceptance_timed_out!

        render json: { booking: BookingSerializer.new(booking, request: request, viewer: current_api_user).as_json }
      end

      def price_preview
        product = Product.active.find(booking_params[:product_id])
        start_time = Time.zone.parse(booking_params[:start_time].to_s)
        end_time = Time.zone.parse(booking_params[:end_time].to_s)

        if start_time.blank? || end_time.blank? || end_time <= start_time
          render json: { error: "Please choose a valid rental schedule." }, status: :unprocessable_entity
          return
        end

        render json: {
          price: Booking.price_breakdown(product: product, start_time: start_time, end_time: end_time)
        }
      rescue ArgumentError, ActiveRecord::RecordNotFound
        render json: { error: "Please choose a valid product and schedule." }, status: :unprocessable_entity
      end

      def create
        product = Product.active.find(booking_params[:product_id])

        if product.owner_id == current_api_user.id
          render json: { error: "You cannot rent your own item." }, status: :unprocessable_entity
          return
        end

        booking = build_booking(product)

        unless booking.valid?
          render json: { error: booking.errors.full_messages.to_sentence }, status: :unprocessable_entity
          return
        end

        unless product.available_for?(booking.start_time, booking.end_time)
          render json: { error: "This item is unavailable for the selected time." }, status: :unprocessable_entity
          return
        end

        price = Booking.price_breakdown(
          product: product,
          start_time: booking.start_time,
          end_time: booking.end_time
        )
        booking.assign_attributes(price)

        product.with_lock do
          unless product.available_for?(booking.start_time, booking.end_time)
            render json: { error: "This item is unavailable for the selected time." }, status: :unprocessable_entity
            return
          end

          booking.save!
          booking.create_product_reservation!(
            product: product,
            renter: current_api_user,
            start_time: booking.start_time,
            end_time: booking.end_time,
            status: "pending",
            reason: "booking"
          )
          Conversations::EnsureBooking.call(booking: booking)
        end

        render json: { booking: BookingSerializer.new(booking, request: request, viewer: current_api_user).as_json }, status: :created
      rescue ArgumentError, ActiveRecord::RecordNotFound
        render json: { error: "Please choose a valid product and schedule." }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid => error
        render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end

      def cancel
        booking = current_api_user.rentals.find(params[:id])

        unless booking.pending? || booking.accepted?
          render json: { error: "This booking cannot be cancelled." }, status: :unprocessable_entity
          return
        end

        ActiveRecord::Base.transaction do
          booking.cancel!
          booking.update!(cancelled_at: Time.current)
          booking.product_reservation&.update!(status: "cancelled")
        end

        render json: { booking: BookingSerializer.new(booking, request: request, viewer: current_api_user).as_json }
      end

      def pay
        booking = current_api_user.rentals.find(params[:id])

        unless booking.accepted?
          render json: { error: "This booking cannot be paid yet." }, status: :unprocessable_entity
          return
        end

        ActiveRecord::Base.transaction do
          payment = booking.payment || booking.build_payment
          payment.update!(
            payer_id: current_api_user.id,
            amount: booking.total_amount.to_i,
            payment_method: "manual",
            status: "paid",
            transaction_id: "MANUAL-#{SecureRandom.hex(8).upcase}",
            paid_at: Time.current
          )
          booking.pay!
        end

        render json: { booking: BookingSerializer.new(booking, request: request, viewer: current_api_user).as_json }
      end

      def confirm_received
        booking = current_api_user.rentals.find(params[:id])

        unless booking.paid? && booking.paid_successfully?
          render json: { error: "Confirm receipt only after payment." }, status: :unprocessable_entity
          return
        end

        ActiveRecord::Base.transaction do
          booking.confirm_pickup!
          booking.update!(picked_up_at: Time.current)
        end

        render json: { booking: BookingSerializer.new(booking, request: request, viewer: current_api_user).as_json }
      end

      private

      def build_booking(product)
        pickup_method = booking_params[:pickup_method].presence || product.available_pickup_methods.first
        address =
          if pickup_method == "self_pickup"
            product.pickup_location
          else
            booking_params[:pickup_address]
          end

        Booking.new(
          product: product,
          owner: product.owner,
          renter: current_api_user,
          start_time: booking_params[:start_time],
          end_time: booking_params[:end_time],
          pickup_method: pickup_method,
          pickup_address: address,
          return_address: address
        )
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
  end
end
