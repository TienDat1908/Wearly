module Admin
  class HomeSpotlightsController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_home_spotlight

    def edit
    end

    def update
      if uploaded_images_count > HomeSpotlight::MAX_IMAGES
        @home_spotlight.errors.add(:images, t("admin.home_spotlight.images_limit_error"))
        return render :edit, status: :unprocessable_entity
      end

      @home_spotlight.replace_look_images!(uploaded_image_files) if uploaded_image_files.any?
      @home_spotlight.assign_attributes(home_spotlight_attributes)

      if @home_spotlight.save
        redirect_to edit_admin_home_spotlight_path, notice: t("flash.admin.home_spotlight.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_home_spotlight
      @home_spotlight = HomeSpotlight
        .with_attached_images
        .with_attached_image
        .order(:position, created_at: :desc)
        .first_or_initialize
    end

    def home_spotlight_attributes
      params.require(:home_spotlight).permit(
        :eyebrow,
        :title,
        :subtitle,
        :active,
        :position,
        :spin_frame_count
      )
    end

    def uploaded_image_files
      Array(params.dig(:home_spotlight, :images)).compact_blank
    end

    def uploaded_images_count
      uploaded_image_files.size
    end
  end
end
