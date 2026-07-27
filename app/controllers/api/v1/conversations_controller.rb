# frozen_string_literal: true

module Api
  module V1
    class ConversationsController < BaseController
      before_action :authenticate_api_user!

      def index
        conversations = Conversation
          .visible_to(current_api_user)
          .includes(:booking, :participants, :messages)
          .recent_first

        render json: {
          conversations: conversations.map { |c| ConversationSerializer.new(c, current_user: current_api_user, request: request).as_json }
        }
      end

      def show
        conversation = Conversation.find(params[:id])
        unless conversation.accessible_by?(current_api_user)
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end

        conversation.mark_read_for!(current_api_user)
        messages = conversation.messages.includes(:sender).order(:created_at)

        render json: {
          conversation: ConversationSerializer.new(conversation, current_user: current_api_user, request: request, detailed: true).as_json,
          messages: messages.map { |m| MessageSerializer.new(m, request: request).as_json }
        }
      end

      def support
        conversation = Conversations::EnsureSupport.call(user: current_api_user)
        render json: {
          conversation: ConversationSerializer.new(conversation, current_user: current_api_user, request: request).as_json
        }
      end

      def booking
        booking = find_user_booking!(params.require(:booking_id))
        unless booking.chattable?
          render json: { error: "Chat is unavailable for this booking status." }, status: :unprocessable_entity
          return
        end

        conversation = Conversations::EnsureBooking.call(booking: booking)
        render json: {
          conversation: ConversationSerializer.new(conversation, current_user: current_api_user, request: request).as_json
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Booking not found." }, status: :not_found
      end

      def create_message
        conversation = Conversation.find(params[:id])
        unless conversation.accessible_by?(current_api_user)
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end

        message = Conversations::PostMessage.call(
          conversation: conversation,
          sender: current_api_user,
          body: params.require(:message).permit(:body)[:body]
        )

        render json: { message: message.as_chat_json }, status: :created
      rescue ArgumentError => error
        render json: { error: error.message }, status: :unprocessable_entity
      end

      private

      def find_user_booking!(booking_id)
        Booking
          .where("renter_id = :uid OR owner_id = :uid", uid: current_api_user.id)
          .find(booking_id)
      end
    end
  end
end
