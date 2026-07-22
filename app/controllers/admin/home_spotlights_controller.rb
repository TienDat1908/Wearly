module Admin
  class HomeSpotlightsController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_home_spotlight

    def edit
    end

    def update
      if uploaded_images_count > 5
        @home_spotlight.errors.add(:images, t("admin.home_spotlight.images_limit_error"))
        return render :edit, status: :unprocessable_entity
      end

      if @home_spotlight.update(home_spotlight_params)
        redirect_to edit_admin_home_spotlight_path, notice: t("flash.admin.home_spotlight.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_home_spotlight
      @home_spotlight = HomeSpotlight.order(:position, created_at: :desc).first_or_initialize
    end

    def home_spotlight_params
      params.require(:home_spotlight).permit(
        :eyebrow,
        :title,
        :subtitle,
        :active,
        :position,
        images: []
      )
    end

    def uploaded_images_count
      Array(params.dig(:home_spotlight, :images)).compact_blank.size
    end
  end
end
