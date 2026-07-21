module Owner
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_owner!
    before_action :set_product, only: [:edit, :update, :destroy]

    def index
      @products = current_user.products.includes(photos_attachments: :blob).order(created_at: :desc)
    end

    def new
      @product = current_user.products.new(
        address: current_user.address,
        city: current_user.city,
        district: current_user.district,
        ward: current_user.ward,
        pickup_available: true,
        delivery_available: true
      )
    end

    def create
      @product = current_user.products.new(product_params)
      @product.status = "active"

      if @product.save
        assign_uploaded_cover_from_index!(@product, starting_after_count: 0)
        redirect_to owner_products_path, notice: t("flash.products.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      existing_photos_count = @product.photos.count
      replacing_photos = replacing_product_photos?
      attributes = product_params
      attributes = attributes.except(:photos) unless replacing_photos

      if replacing_photos
        @product.update_column(:primary_photo_attachment_id, nil)
        attributes = attributes.except(:primary_photo_attachment_id)
      end

      if @product.update(attributes)
        if replacing_photos
          assign_uploaded_cover_from_index!(@product, starting_after_count: 0)
          assign_first_photo_as_cover!(@product)
        else
          assign_uploaded_cover_from_index!(@product, starting_after_count: existing_photos_count)
        end

        redirect_to owner_products_path, notice: t("flash.products.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.update_columns(status: "inactive", updated_at: Time.current)
      redirect_to owner_products_path, notice: t("flash.products.archived")
    end

    private

    def set_product
      @product = current_user.products.find(params[:id])
    end

    def require_owner!
      return if current_user.owner?

      if current_user.admin?
        redirect_to admin_root_path, alert: t("flash.auth.owner_area_unavailable")
        return
      end

      redirect_to root_path, alert: t("flash.auth.owner_required")
    end

    def product_params
      params.require(:product).permit(
        :title,
        :product_type,
        :description,
        :condition_status,
        :size,
        :color,
        :gender,
        :age_group,
        :brand,
        :price_per_day,
        :deposit_amount,
        :cleaning_fee,
        :replacement_value,
        :address,
        :city,
        :district,
        :ward,
        :pickup_available,
        :delivery_available,
        :primary_photo_attachment_id,
        photos: []
      )
    end

    def assign_uploaded_cover_from_index!(product, starting_after_count:)
      index = params.dig(:product, :primary_photo_index)
      return if index.blank?

      selected_photo = product
        .photos
        .attachments
        .order(:created_at, :id)
        .offset(starting_after_count)
        .to_a[index.to_i]

      return unless selected_photo

      product.update_column(:primary_photo_attachment_id, selected_photo.id)
    end

    def assign_first_photo_as_cover!(product)
      return if product.primary_photo_attachment_id.present?

      first_photo = product.photos.attachments.order(:created_at, :id).first
      product.update_column(:primary_photo_attachment_id, first_photo.id) if first_photo
    end

    def replacing_product_photos?
      uploaded_product_photos.any?
    end

    def uploaded_product_photos
      Array(params.dig(:product, :photos)).compact_blank
    end
  end
end
