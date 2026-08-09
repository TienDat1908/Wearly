# frozen_string_literal: true

module Api
  module V1
    class BookingSerializer
      def initialize(booking, request:, viewer: nil)
        @booking = booking
        @request = request
        @viewer = viewer
      end

      def as_json
        {
          id: booking.id,
          status: booking.status,
          start_time: booking.start_time&.iso8601,
          end_time: booking.end_time&.iso8601,
          rental_days: booking.rental_days.to_i,
          rental_amount: booking.rental_amount.to_i,
          cleaning_fee: booking.cleaning_fee.to_i,
          delivery_fee: booking.delivery_fee.to_i,
          deposit_amount: booking.deposit_amount.to_i,
          renter_service_fee_amount: booking.renter_service_fee_amount.to_i,
          platform_fee_amount: booking.platform_fee_amount.to_i,
          owner_earning_amount: booking.owner_earning_amount.to_i,
          total_amount: booking.total_amount.to_i,
          pickup_method: booking.pickup_method,
          pickup_address: booking.pickup_address,
          return_address: booking.return_address,
          payment_status: booking.payment&.status,
          paid_successfully: booking.paid_successfully?,
          chattable: booking.chattable?,
          completable: booking.completable?,
          product: ProductSerializer.new(booking.product, request: request).as_json,
          owner: UserSerializer.new(booking.owner, request: request, public_profile: true).as_json,
          renter: UserSerializer.new(booking.renter, request: request, public_profile: true).as_json,
          created_at: booking.created_at&.iso8601,
          acceptance_deadline_at: booking.acceptance_deadline&.iso8601,
          cancel_reason: booking.cancel_reason,
          actions: actions_for_viewer
        }
      end

      private

      attr_reader :booking, :request, :viewer

      def actions_for_viewer
        return default_actions if viewer.blank?

        if viewer.id == booking.renter_id
          {
            cancel: booking.pending? || booking.accepted?,
            pay: booking.accepted?,
            confirm_received: booking.paid? && booking.paid_successfully?,
            chat: booking.chattable?,
            accept: false,
            reject: false,
            complete: false
          }
        elsif viewer.id == booking.owner_id
          {
            cancel: false,
            pay: false,
            confirm_received: false,
            chat: booking.chattable?,
            accept: booking.pending?,
            reject: booking.pending?,
            complete: booking.completable?
          }
        else
          default_actions
        end
      end

      def default_actions
        {
          cancel: false,
          pay: false,
          confirm_received: false,
          chat: false,
          accept: false,
          reject: false,
          complete: false
        }
      end
    end
  end
end
