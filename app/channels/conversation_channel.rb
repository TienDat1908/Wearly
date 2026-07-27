# frozen_string_literal: true

class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find_by(id: params[:id])
    unless conversation&.accessible_by?(current_user)
      reject
      return
    end

    stream_for conversation
  end
end
