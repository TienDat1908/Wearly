module Api
  module V1
    class BookingSerializer
      def initialize(booking, request:)
        @booking = booking
        @request = request
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
          product: ProductSerializer.new(booking.product, request: request).as_json,
          owner: UserSerializer.new(booking.owner, request: request).as_json,
          renter: UserSerializer.new(booking.renter, request: request).as_json,
          created_at: booking.created_at&.iso8601
        }
      end

      private

      attr_reader :booking, :request
    end
  end
end
