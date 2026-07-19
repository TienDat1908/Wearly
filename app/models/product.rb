class Product < ApplicationRecord
  include PgSearch::Model

  belongs_to :owner, class_name: "User"

  has_many_attached :photos

  has_many :bookings, dependent: :restrict_with_error
  has_many :product_reservations, dependent: :restrict_with_error
  has_many :reviews, dependent: :destroy

  enum :status, {
    draft: "draft",
    active: "active",
    rented: "rented",
    inactive: "inactive"
  }, default: "draft"

  enum :product_type, {
    dress: "dress",
    outfit: "outfit",
    shirt: "shirt",
    pants: "pants",
    camera: "camera",
    lens: "lens",
    accessory: "accessory",
    other: "other"
  }

  validates :title, :product_type, :price_per_day, presence: true
  validates :price_per_day, numericality: { greater_than: 0 }
  validates :address, presence: true, if: :pickup_available?
  validate :at_least_one_fulfillment_method

  pg_search_scope :search_by_keyword,
    against: [:title, :description, :brand, :color, :size, :city],
    using: {
      tsearch: { prefix: true }
    }

  def available_for?(start_time, end_time)
    product_reservations
      .where(status: ["pending", "confirmed"])
      .where("start_time < ? AND end_time > ?", end_time, start_time)
      .none?
  end

  def available_pickup_methods
    methods = []
    methods << "self_pickup" if pickup_available? && pickup_location.present?
    methods << "delivery" if delivery_available?
    return methods if methods.any?

    pickup_location.present? ? %w[self_pickup delivery] : %w[delivery]
  end

  def cover_photo
    selected_cover_photo || photos.first
  end

  def cover_photo_attachment_id
    selected_cover_photo&.id || self[:primary_photo_attachment_id]
  end

  def photo_gallery
    return photos unless cover_photo_attachment_id.present?

    photos.sort_by { |photo| photo.id == cover_photo_attachment_id ? 0 : 1 }
  end

  def pickup_location
    product_address = [address, ward, district, city].compact_blank.join(", ")
    return product_address if product_address.present?

    [owner.address, owner.ward, owner.district, owner.city].compact_blank.join(", ")
  end

  private

  def selected_cover_photo
    return unless self[:primary_photo_attachment_id].present?

    photos.detect { |photo| photo.id == self[:primary_photo_attachment_id] }
  end

  def at_least_one_fulfillment_method
    return if pickup_available? || delivery_available?

    errors.add(:base, :fulfillment_method_required)
  end
end
