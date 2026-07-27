# frozen_string_literal: true

class ExpirePendingBookingJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(booking_id)
    booking = Booking.find_by(id: booking_id)
    return unless booking

    booking.expire_if_acceptance_timed_out!
  end
end
