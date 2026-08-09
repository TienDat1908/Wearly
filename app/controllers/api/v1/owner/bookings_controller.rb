# frozen_string_literal: true

module Api
  module V1
    module Owner
      class BookingsController < BaseController
        before_action :set_booking, only: [:show, :accept, :reject, :complete]

        def index
          bookings = current_api_user
            .owner_bookings
            .includes(:renter, :payment, product: [photos_attachments: :blob])
            .order(created_at: :desc)

          bookings.find_each(&:expire_if_acceptance_timed_out!)

          render json: {
            bookings: bookings.reload.map { |booking| BookingSerializer.new(booking, request: request, viewer: current_api_user).as_json }
          }
        end

        def show
          render json: { booking: BookingSerializer.new(@booking, request: request, viewer: current_api_user).as_json }
        end

        def accept
          unless @booking.pending?
            render json: { error: acceptance_blocked_error }, status: :unprocessable_entity
            return
          end

          ActiveRecord::Base.transaction do
            @booking.accept!
            @booking.update!(accepted_at: Time.current)
            @booking.product_reservation&.update!(status: "confirmed")
            Conversations::EnsureBooking.call(booking: @booking)
          end

          render json: { booking: BookingSerializer.new(@booking, request: request, viewer: current_api_user).as_json }
        end

        def reject
          unless @booking.pending?
            render json: { error: acceptance_blocked_error }, status: :unprocessable_entity
            return
          end

          ActiveRecord::Base.transaction do
            @booking.reject!
            @booking.update!(rejected_at: Time.current)
            @booking.product_reservation&.update!(status: "cancelled")
          end

          render json: { booking: BookingSerializer.new(@booking, request: request, viewer: current_api_user).as_json }
        end

        def complete
          unless @booking.completable?
            render json: { error: "This booking cannot be completed yet." }, status: :unprocessable_entity
            return
          end

          ActiveRecord::Base.transaction do
            @booking.complete!
            @booking.update!(returned_at: Time.current, completed_at: Time.current)
            @booking.product_reservation&.update!(status: "cancelled")

            Payout.find_or_create_by!(booking: @booking) do |payout|
              payout.owner_id = @booking.owner_id
              payout.amount = @booking.owner_earning_amount.to_i
              payout.status = "pending"
              payout.payout_method = "manual"
            end
          end

          render json: { booking: BookingSerializer.new(@booking, request: request, viewer: current_api_user).as_json }
        end

        private

        def set_booking
          @booking = current_api_user
            .owner_bookings
            .includes(:renter, :payment, product: [photos_attachments: :blob])
            .find(params[:id])
          @booking.expire_if_acceptance_timed_out!
        end

        def acceptance_blocked_error
          if @booking.acceptance_timed_out?
            "Acceptance window has expired."
          else
            "This booking cannot be updated."
          end
        end
      end
    end
  end
end
