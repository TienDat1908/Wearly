class HomeSpotlight < ApplicationRecord
  MAX_IMAGES = 5
  MAX_IMAGE_SIZE = 12.megabytes
  MIN_SPIN_FRAMES = 1
  MAX_SPIN_FRAMES = 36
  SAFE_IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze

  belongs_to :product, optional: true
  has_one_attached :image
  has_many_attached :images
  has_one_attached :spin_sheet # legacy; Look #1 strip is preferred

  scope :active, -> { where(active: true).order(:position, created_at: :desc) }

  validates :eyebrow, :title, presence: true
  validates :spin_frame_count,
    numericality: { only_integer: true, greater_than_or_equal_to: MIN_SPIN_FRAMES, less_than_or_equal_to: MAX_SPIN_FRAMES }
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

  def runway_images
    display_images.first(MAX_IMAGES)
  end

  # Each look image can be a horizontal strip when frame count is 2+.
  def spin_enabled?
    spin_frame_count.to_i >= 2 && display_images.any?
  end

  def spin_source_attachment
    return nil unless spin_enabled?

    display_images.first
  end

  def replace_look_images!(uploaded_files)
    files = Array(uploaded_files).compact_blank
    return false if files.empty?

    images.purge if images.attached?
    image.purge if image.attached?
    spin_sheet.purge if spin_sheet.attached?
    self.images = files
    true
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
