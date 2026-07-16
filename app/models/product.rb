class Product < ApplicationRecord
  include PgSearch::Model

  belongs_to :owner, class_name: "User"

  has_many_attached :photos

  has_many :bookings, dependent: :destroy
  has_many :product_reservations, dependent: :destroy
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
end
