# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show]

  def index
    @conversations = Conversation
      .visible_to(current_user)
      .includes(:participants, messages: :sender)
      .recent_first
  end

  def show
    @messages = @conversation.messages.includes(:sender).order(:created_at)
    @conversation.mark_read_for!(current_user)
    @message = Message.new
  end

  def support
    conversation = Conversations::EnsureSupport.call(user: current_user)
    redirect_to conversation_path(conversation)
  end

  def create_message
    conversation = Conversation.find(params[:id])
    unless conversation.accessible_by?(current_user)
      respond_to do |format|
        format.html { redirect_to conversations_path, alert: t("flash.conversations.forbidden") }
        format.json { render json: { error: "Forbidden" }, status: :forbidden }
      end
      return
    end

    message = Conversations::PostMessage.call(
      conversation: conversation,
      sender: current_user,
      body: params.require(:message).permit(:body)[:body]
    )

    respond_to do |format|
      format.html { redirect_to conversation_path(conversation) }
      format.json { render json: { message: message.as_chat_json }, status: :created }
    end
  rescue ArgumentError
    respond_to do |format|
      format.html { redirect_to conversation_path(conversation), alert: t("flash.conversations.message_invalid") }
      format.json { render json: { error: "invalid" }, status: :unprocessable_entity }
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
    return if @conversation.accessible_by?(current_user)

    redirect_to conversations_path, alert: t("flash.conversations.forbidden")
  end
end
