# frozen_string_literal: true

class Conversations::PostMessage
  def self.call(conversation:, sender:, body:)
    new(conversation:, sender:, body:).call
  end

  def initialize(conversation:, sender:, body:)
    @conversation = conversation
    @sender = sender
    @body = body.to_s.strip
  end

  def call
    raise ArgumentError, "empty" if body.blank?
    raise ArgumentError, "forbidden" unless conversation.accessible_by?(sender)

    Message.transaction do
      message = conversation.messages.create!(sender: sender, body: body)

      # Ensure admin becomes a participant on first support reply so unread works.
      if conversation.support? && sender.admin?
        conversation.conversation_participants.find_or_create_by!(user: sender) do |row|
          row.last_read_at = Time.current
        end
      end

      conversation.mark_read_for!(sender)
      message
    end
  end

  private

  attr_reader :conversation, :sender, :body
end
