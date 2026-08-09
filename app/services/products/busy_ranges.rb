# frozen_string_literal: true

module Products
  class BusyRanges
    Result = Struct.new(:from, :to, :busy, keyword_init: true)

    def self.call(product:, from:, to:, include_booking_details: false)
      new(
        product: product,
        from: from,
        to: to,
        include_booking_details: include_booking_details
      ).call
    end

    def initialize(product:, from:, to:, include_booking_details: false)
      @product = product
      @from = from.to_date
      @to = to.to_date
      @include_booking_details = include_booking_details
    end

    def call
      Result.new(from: from, to: to, busy: booking_ranges + block_ranges)
    end

    private

    attr_reader :product, :from, :to, :include_booking_details

    def booking_ranges
      product.product_reservations
        .where(status: %w[pending confirmed])
        .where("start_time < ? AND end_time >= ?", (to + 1).beginning_of_day, from.beginning_of_day)
        .includes(:booking)
        .map do |reservation|
          payload = {
            kind: "booking",
            start_on: reservation.start_time.to_date.iso8601,
            end_on: reservation.end_time.to_date.iso8601,
            status: reservation.status
          }

          if include_booking_details
            payload[:booking_id] = reservation.booking_id
            payload[:reservation_id] = reservation.id
          end

          payload
        end
    end

    def block_ranges
      product.product_blocked_dates
        .overlapping(from, to)
        .order(:start_on, :id)
        .map do |block|
          {
            kind: "block",
            id: block.id,
            start_on: block.start_on.iso8601,
            end_on: block.end_on.iso8601,
            note: block.note
          }
        end
    end
  end
end
