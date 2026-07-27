# frozen_string_literal: true

module Admin
  class ConversationsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_conversation, only: [:show]

    def index
      @conversations = Conversation
        .support
        .includes(:participants, messages: :sender)
        .recent_first
    end

    def show
      @messages = @conversation.messages.includes(:sender).order(:created_at)
      @conversation.mark_read_for!(current_user) if @conversation.conversation_participants.exists?(user_id: current_user.id)
      @message = Message.new
    end

    def create_message
      conversation = Conversation.support.find(params[:id])
      message = Conversations::PostMessage.call(
        conversation: conversation,
        sender: current_user,
        body: params.require(:message).permit(:body)[:body]
      )

      respond_to do |format|
        format.html { redirect_to admin_conversation_path(conversation) }
        format.json { render json: { message: message.as_chat_json }, status: :created }
      end
    rescue ArgumentError
      respond_to do |format|
        format.html { redirect_to admin_conversation_path(params[:id]), alert: t("flash.conversations.message_invalid") }
        format.json { render json: { error: "invalid" }, status: :unprocessable_entity }
      end
    end

    private

    def set_conversation
      @conversation = Conversation.support.find(params[:id])
    end
  end
end
