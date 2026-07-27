# frozen_string_literal: true

class Conversations::NotifyBookingRequested
  include Rails.application.routes.url_helpers

  def self.call(conversation:, booking:)
    new(conversation:, booking:).call
  end

  def initialize(conversation:, booking:)
    @conversation = conversation
    @booking = booking
  end

  def call
    return if conversation.messages.where(system: true, booking_id: booking.id).exists?

    locale = booking.owner.preferred_locale.presence || I18n.default_locale

    body = I18n.with_locale(locale) do
      I18n.t(
        "conversations.system.booking_requested",
        product: booking.product.title,
        renter: booking.renter.full_name.presence || booking.renter.email,
        start: I18n.l(booking.start_time, format: :short),
        end: I18n.l(booking.end_time, format: :short),
        path: owner_booking_path(booking, locale: locale)
      )
    end

    conversation.messages.create!(
      sender: booking.renter,
      body: body,
      system: true,
      booking_id: booking.id
    )
  end

  private

  attr_reader :conversation, :booking
end
