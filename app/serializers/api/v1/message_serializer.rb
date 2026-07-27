# frozen_string_literal: true

module Api
  module V1
    class MessageSerializer
      def initialize(message, request:)
        @message = message
        @request = request
      end

      def as_json
        {
          id: message.id,
          body: message.body,
          system: message.system?,
          booking_id: message.booking_id,
          created_at: message.created_at&.iso8601,
          sender: UserSerializer.new(message.sender, request: request, public_profile: true).as_json
        }
      end

      private

      attr_reader :message, :request
    end
  end
end
