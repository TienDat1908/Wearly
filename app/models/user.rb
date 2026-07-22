class User < ApplicationRecord
  MAX_AVATAR_SIZE = 5.megabytes
  SAFE_AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  attr_writer :login
  attr_accessor :oauth_signup

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2, :facebook, :instagram]

  has_one_attached :avatar

  has_many :social_accounts, dependent: :destroy
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
  validates :phone, presence: true, uniqueness: true, unless: :oauth_signup?
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  validate :password_complexity
  validate :avatar_is_safe

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

  def self.find_for_omniauth(auth)
    social_account = SocialAccount.find_by(provider: auth.provider, uid: auth.uid)
    return social_account.user if social_account.present?

    email = auth.info.email.to_s.downcase.strip
    user = email.present? ? User.find_by(email: email) : nil
    return connect_omniauth_account(user, auth) if user.present?

    nil
  end

  def self.from_omniauth(auth)
    find_for_omniauth(auth)
  end

  def self.create_from_omniauth(auth, attributes = {})
    user = User.new(
      email: attributes[:email].presence || oauth_email(auth),
      full_name: attributes[:full_name].presence || oauth_name(auth),
      phone: attributes[:phone],
      preferred_locale: attributes[:preferred_locale].presence || I18n.locale.to_s,
      role: attributes[:role].presence || "renter",
      status: "active",
      password: oauth_password,
      oauth_signup: true
    )

    connect_omniauth_account(user, auth)
  end

  def self.pending_omniauth_attributes(auth)
    {
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email.to_s.downcase.strip.presence,
      name: oauth_name(auth),
      avatar_url: auth.info.image.presence
    }
  end

  def self.connect_omniauth_account(user, auth)
    user.oauth_signup = true if user.new_record? || user.phone.blank?
    user.social_accounts.build(
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email.to_s.downcase.strip.presence,
      name: oauth_name(auth),
      avatar_url: auth.info.image.presence
    ) unless user.social_accounts.exists?(provider: auth.provider)

    user.save!
    user
  end

  def password_required?
    return false if oauth_signup?
    super
  end

  private

  def self.oauth_email(auth)
    email = auth.info.email.to_s.downcase.strip
    return email if email.present?

    "#{auth.provider}-#{auth.uid}@oauth.wearly.local"
  end

  def self.oauth_name(auth)
    auth.info.name.presence || auth.info.nickname.presence || "Wearly member"
  end

  def self.oauth_password
    "Aa1!#{Devise.friendly_token[0, 32]}"
  end

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def normalize_phone
    normalized_phone = phone.to_s.gsub(/\s+/, "").strip
    self.phone = normalized_phone.presence
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

  def oauth_signup?
    oauth_signup == true || oauth_signup == "true"
  end

  def avatar_is_safe
    return unless avatar.attached?

    if avatar.blob.byte_size > MAX_AVATAR_SIZE
      errors.add(:avatar, "must be smaller than #{MAX_AVATAR_SIZE / 1.megabyte}MB")
    end

    return if SAFE_AVATAR_CONTENT_TYPES.include?(avatar.blob.content_type)

    errors.add(:avatar, "must be a JPG, PNG, or WebP image")
  end
end
