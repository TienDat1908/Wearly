class User < ApplicationRecord
  attr_writer :login

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  has_many :products, foreign_key: :owner_id, dependent: :destroy
  has_many :rentals, class_name: "Booking", foreign_key: :renter_id, dependent: :destroy
  has_many :owner_bookings, class_name: "Booking", foreign_key: :owner_id, dependent: :destroy

  enum :role, {
    renter: "renter",
    owner: "owner",
    admin: "admin"
  }, default: "renter"

  enum :status, {
    active: "active",
    blocked: "blocked"
  }, default: "active"

  before_validation :normalize_email
  before_validation :normalize_phone
  before_validation :set_default_locale

  validates :full_name, presence: true
  validates :phone, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  validate :password_complexity

  def login
    @login || email || phone
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)&.downcase&.strip

    where(conditions)
      .where("LOWER(email) = :value OR phone = :value", value: login)
      .first
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def normalize_phone
    self.phone = phone.to_s.gsub(/\s+/, "").strip
  end

  def set_default_locale
    self.preferred_locale = "en" if preferred_locale.blank?
  end

  def password_complexity
    return if password.blank?

    valid_password =
      password.length >= 8 &&
      password.match?(/[A-Z]/) &&
      password.match?(/[0-9]/) &&
      password.match?(/[^A-Za-z0-9]/)

    errors.add(:password, :complexity) unless valid_password
  end
end
