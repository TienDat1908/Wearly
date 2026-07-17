class Payout < ApplicationRecord
  belongs_to :booking
  belongs_to :owner, class_name: "User"

  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed"
  }, default: "pending"

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
