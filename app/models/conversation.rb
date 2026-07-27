# frozen_string_literal: true

class Conversation < ApplicationRecord
  KINDS = %w[support booking].freeze

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }
  validates :pair_key, presence: true, uniqueness: true, if: :booking_chat?
  validate :pair_key_forbidden_for_support_kind

  scope :support, -> { where(kind: "support") }
  scope :booking_kind, -> { where(kind: "booking") }
  scope :recent_first, -> { order(Arel.sql("COALESCE(conversations.last_message_at, conversations.created_at) DESC")) }

  def self.pair_key_for(user_a_id, user_b_id)
    [user_a_id.to_i, user_b_id.to_i].minmax.join(":")
  end

  def self.find_direct_between(user_a_id, user_b_id)
    booking_kind.find_by(pair_key: pair_key_for(user_a_id, user_b_id))
  end

  def support?
    kind == "support"
  end

  def booking_chat?
    kind == "booking"
  end

  def accessible_by?(user)
    return false if user.blank?
    return true if user.admin? && support?
    return true if booking_chat? && user.admin?

    conversation_participants.exists?(user_id: user.id)
  end

  def other_participant_for(user)
    participants.where.not(id: user.id).first
  end

  def mark_read_for!(user)
    conversation_participants.find_by(user_id: user.id)&.update!(last_read_at: Time.current)
  end

  def unread_count_for(user)
    participant = conversation_participants.find_by(user_id: user.id)
    return 0 unless participant

    scope = messages.where.not(sender_id: user.id)
    if participant.last_read_at.present?
      scope = scope.where("messages.created_at > ?", participant.last_read_at)
    end
    scope.count
  end

  def latest_related_booking
    messages.where.not(booking_id: nil).order(created_at: :desc).limit(1).first&.booking
  end

  def self.visible_to(user)
    return none if user.blank?

    participant_ids = ConversationParticipant.where(user_id: user.id).select(:conversation_id)

    if user.admin?
      where(kind: "support").or(where(id: participant_ids))
    else
      where(id: participant_ids)
    end
  end

  private

  def pair_key_forbidden_for_support_kind
    return unless support?
    return if pair_key.blank?

    errors.add(:pair_key, :present)
  end
end
