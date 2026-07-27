# frozen_string_literal: true

class Conversations::EnsureSupport
  def self.call(user:)
    new(user:).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    existing = Conversation
      .support
      .joins(:conversation_participants)
      .find_by(conversation_participants: { user_id: user.id })

    return existing if existing

    Conversation.transaction do
      conversation = Conversation.create!(
        kind: "support",
        subject: "Wearly Support"
      )
      conversation.conversation_participants.create!(user: user, last_read_at: Time.current)
      conversation
    end
  end

  private

  attr_reader :user
end
