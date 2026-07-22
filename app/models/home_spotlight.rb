class HomeSpotlight < ApplicationRecord
  MAX_IMAGES = 5
  MAX_IMAGE_SIZE = 8.megabytes
  SAFE_IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :product, optional: true
  has_one_attached :image
  has_many_attached :images

  scope :active, -> { where(active: true).order(:position, created_at: :desc) }

  validates :eyebrow, :title, presence: true
  validate :images_limit
  validate :images_are_safe

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
    return unless images.attachments.size > MAX_IMAGES

    errors.add(:images, :too_many, message: "must be #{MAX_IMAGES} images or fewer")
  end

  def images_are_safe
    display_images.each do |attachment|
      blob = attachment.blob
      next unless blob

      if blob.byte_size > MAX_IMAGE_SIZE
        errors.add(:images, "must be smaller than #{MAX_IMAGE_SIZE / 1.megabyte}MB each")
      end

      next if safe_image_content_types.include?(blob.content_type)

      errors.add(:images, "must be JPG, PNG, or WebP images")
    end
  end

  def safe_image_content_types
    return SAFE_IMAGE_CONTENT_TYPES unless Rails.env.development?

    SAFE_IMAGE_CONTENT_TYPES + %w[image/svg+xml]
  end
end
