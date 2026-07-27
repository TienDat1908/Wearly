# frozen_string_literal: true

module Api
  module V1
    class ConversationSerializer
      def initialize(conversation, current_user:, request:, detailed: false)
        @conversation = conversation
        @current_user = current_user
        @request = request
        @detailed = detailed
      end

      def as_json
        counterpart = conversation.support? ? nil : conversation.other_participant_for(current_user)
        last_message = conversation.messages.max_by(&:created_at)

        {
          id: conversation.id,
          kind: conversation.kind,
          subject: conversation_title,
          booking_id: conversation.latest_related_booking&.id,
          last_message_at: conversation.last_message_at&.iso8601,
          unread_count: conversation.unread_count_for(current_user),
          last_message_preview: last_message&.body.to_s.truncate(120),
          counterpart: counterpart ? UserSerializer.new(counterpart, request: request, public_profile: true).as_json : support_counterpart
        }
      end

      private

      attr_reader :conversation, :current_user, :request, :detailed

      def conversation_title
        return conversation.subject.presence || "Wearly Support" if conversation.support?

        conversation.other_participant_for(current_user)&.full_name.presence ||
          conversation.subject.presence ||
          "Booking chat"
      end

      def support_counterpart
        {
          id: nil,
          full_name: "Wearly Support",
          role: "admin"
        }
      end
    end
  end
end
