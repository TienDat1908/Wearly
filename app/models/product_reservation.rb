class ProductReservation < ApplicationRecord
  belongs_to :product
  belongs_to :booking
  belongs_to :renter, class_name: "User"

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    cancelled: "cancelled"
  }, default: "pending"
end
