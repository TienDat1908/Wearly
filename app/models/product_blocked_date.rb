# frozen_string_literal: true

class ProductBlockedDate < ApplicationRecord
  belongs_to :product

  validates :start_on, :end_on, presence: true
  validate :end_on_after_start_on

  scope :overlapping, lambda { |start_on, end_on|
    where("start_on <= ? AND end_on >= ?", end_on, start_on)
  }

  private

  def end_on_after_start_on
    return if start_on.blank? || end_on.blank?
    return if end_on >= start_on

    errors.add(:end_on, :greater_than_or_equal_to, count: :start_on)
  end
end
