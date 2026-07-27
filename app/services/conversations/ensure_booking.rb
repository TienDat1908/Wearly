# frozen_string_literal: true

# Ensures one shared chat thread for a renter↔owner pair (not one chat per booking).
class Conversations::EnsureBooking
  def self.call(booking:)
    new(booking:).call
  end

  def initialize(booking:)
    @booking = booking
  end

  def call
    pair_key = Conversation.pair_key_for(booking.renter_id, booking.owner_id)

    Conversation.transaction do
      conversation = Conversation.booking_kind.lock.find_by(pair_key: pair_key)

      if conversation.blank?
        begin
          conversation = Conversation.create!(
            kind: "booking",
            pair_key: pair_key,
            subject: counterpart_subject
          )
          conversation.conversation_participants.create!(user: booking.renter, last_read_at: Time.current)
          conversation.conversation_participants.create!(user: booking.owner, last_read_at: nil)
        rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
          conversation = Conversation.booking_kind.lock.find_by!(pair_key: pair_key)
        end
      end

      Conversations::NotifyBookingRequested.call(conversation:, booking:)
      conversation
    end
  end

  private

  attr_reader :booking

  def counterpart_subject
    [
      booking.renter.full_name.presence || booking.renter.email,
      booking.owner.full_name.presence || booking.owner.email
    ].join(" · ")
  end
end
