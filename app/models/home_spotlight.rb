class HomeSpotlight < ApplicationRecord
  belongs_to :product, optional: true
  has_one_attached :image
  has_many_attached :images

  scope :active, -> { where(active: true).order(:position, created_at: :desc) }

  validates :eyebrow, :title, presence: true
  validate :images_limit

  def display_image
    display_images.first
  end

  def display_images
    return images.attachments if images.attached?
    return [image.attachment] if image.attached?

    []
  end

  private

  def images_limit
    return unless images.attachments.size > 5

    errors.add(:images, :too_many, message: "must be 5 images or fewer")
  end
end
