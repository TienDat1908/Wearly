class Payment < ApplicationRecord
  belongs_to :booking
  belongs_to :payer, class_name: "User"

  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed",
    refunded: "refunded"
  }, default: "pending"

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
