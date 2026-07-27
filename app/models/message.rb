# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"
  belongs_to :booking, optional: true

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :system_notices, -> { where(system: true) }

  after_create_commit :touch_conversation_timestamp
  after_create_commit :broadcast_to_conversation

  def system?
    system
  end

  def as_chat_json
    {
      id: id,
      body: body,
      system: system?,
      booking_id: booking_id,
      created_at: created_at&.iso8601,
      sender: {
        id: sender_id,
        full_name: sender.full_name,
        role: sender.role
      }
    }
  end

  private

  def touch_conversation_timestamp
    conversation.update_column(:last_message_at, created_at)
  end

  def broadcast_to_conversation
    ConversationChannel.broadcast_to(
      conversation,
      {
        type: "message_created",
        message: as_chat_json
      }
    )
  end
end
