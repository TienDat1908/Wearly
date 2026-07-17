class Booking < ApplicationRecord
  include AASM

  OWNER_PLATFORM_FEE_RATE = 15
  RENTER_SERVICE_FEE_RATE = 5

  belongs_to :product
  belongs_to :owner, class_name: "User"
  belongs_to :renter, class_name: "User"

  has_one :payment, dependent: :destroy
  has_one :product_reservation, dependent: :destroy
  has_one :payout, dependent: :destroy

  validates :start_time, :end_time, presence: true
  validates :pickup_method, inclusion: { in: %w[self_pickup delivery] }
  validates :pickup_address, :return_address, presence: true
  validate :end_time_after_start_time
  validate :pickup_method_supported_by_product

  scope :revenue_recognized, -> { where(status: ["paid", "picked_up", "completed"]) }

  def self.price_breakdown(product:, start_time:, end_time:)
    rental_days = (end_time.to_date - start_time.to_date).to_i + 1
    rental_amount = product.price_per_day.to_i * rental_days
    cleaning_fee = product.cleaning_fee.to_i
    delivery_fee = 0
    deposit_amount = product.deposit_amount.to_i
    discount_amount = 0
    platform_fee_rate = OWNER_PLATFORM_FEE_RATE
    renter_service_fee_rate = RENTER_SERVICE_FEE_RATE
    platform_fee_amount = (rental_amount * platform_fee_rate / 100.0).round
    renter_service_fee_amount = (rental_amount * renter_service_fee_rate / 100.0).round
    owner_earning_amount = rental_amount + cleaning_fee + delivery_fee - platform_fee_amount
    total_amount =
      rental_amount + cleaning_fee + delivery_fee + deposit_amount +
      renter_service_fee_amount - discount_amount

    {
      rental_days: rental_days,
      rental_amount: rental_amount,
      cleaning_fee: cleaning_fee,
      delivery_fee: delivery_fee,
      deposit_amount: deposit_amount,
      discount_amount: discount_amount,
      platform_fee_rate: platform_fee_rate,
      platform_fee_amount: platform_fee_amount,
      renter_service_fee_rate: renter_service_fee_rate,
      renter_service_fee_amount: renter_service_fee_amount,
      owner_earning_amount: owner_earning_amount,
      total_amount: total_amount
    }
  end

  def admin_revenue_amount
    platform_fee_amount.to_i + renter_service_fee_amount.to_i
  end

  def gmv_amount
    rental_amount.to_i + cleaning_fee.to_i + delivery_fee.to_i - discount_amount.to_i
  end

  def owner_gross_amount
    rental_amount.to_i + cleaning_fee.to_i + delivery_fee.to_i
  end

  def paid_successfully?
    payment&.status == "paid"
  end

  def rental_period_ended?
    end_time.present? && end_time <= Time.current
  end

  def completable?
    picked_up? && rental_period_ended?
  end

  def self.gmv
    sum(:rental_amount).to_i + sum(:cleaning_fee).to_i +
      sum(:delivery_fee).to_i - sum(:discount_amount).to_i
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
    state :paid
    state :picked_up
    state :rejected
    state :cancelled
    state :completed

    event :accept do
      transitions from: :pending, to: :accepted
    end

    event :pay do
      transitions from: :accepted, to: :paid
    end

    event :confirm_pickup do
      transitions from: :paid, to: :picked_up
    end

    event :reject do
      transitions from: :pending, to: :rejected
    end

    event :cancel do
      transitions from: [:pending, :accepted], to: :cancelled
    end

    event :complete do
      transitions from: :picked_up, to: :completed
    end
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    return if end_time > start_time

    errors.add(:end_time, :after_start_time)
  end

  def pickup_method_supported_by_product
    return if product.blank? || pickup_method.blank?
    return if product.available_pickup_methods.include?(pickup_method)

    errors.add(:pickup_method, :unsupported)
  end
end
