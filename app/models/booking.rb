class Booking < ApplicationRecord
  include AASM

  OWNER_PLATFORM_FEE_RATE = 15
  RENTER_SERVICE_FEE_RATE = 5

  belongs_to :product
  belongs_to :owner, class_name: "User"
  belongs_to :renter, class_name: "User"

  has_one :payment, dependent: :destroy
  has_one :product_reservation, dependent: :destroy

  def self.gmv
    sum(:total_amount).to_i
  end

  def self.platform_revenue
    sum(:platform_fee_amount).to_i + sum(:renter_service_fee_amount).to_i
  end

  def self.owner_platform_fee_revenue
    sum(:platform_fee_amount).to_i
  end

  def self.renter_service_fee_revenue
    sum(:renter_service_fee_amount).to_i
  end

  def self.owner_payout_amount
    sum(:owner_earning_amount).to_i
  end

  def self.deposit_amount_total
    sum(:deposit_amount).to_i
  end

  aasm column: :status do
    state :pending, initial: true
    state :accepted
    state :rejected
    state :cancelled
    state :completed

    event :accept do
      transitions from: :pending, to: :accepted
    end

    event :reject do
      transitions from: :pending, to: :rejected
    end

    event :cancel do
      transitions from: [:pending, :accepted], to: :cancelled
    end

    event :complete do
      transitions from: :accepted, to: :completed
    end
  end
end
