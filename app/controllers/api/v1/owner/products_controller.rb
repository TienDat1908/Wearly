# frozen_string_literal: true

module Api
  module V1
    module Owner
      class ProductsController < BaseController
        before_action :set_product, only: [:show, :update, :destroy]

        def index
          products = current_api_user.products.includes(photos_attachments: :blob).order(created_at: :desc)

          render json: {
            products: products.map { |product| ProductSerializer.new(product, request: request, detailed: true).as_json }
          }
        end

        def show
          render json: { product: ProductSerializer.new(@product, request: request, detailed: true).as_json }
        end

        def create
          product = current_api_user.products.new(product_params)
          product.status = "active"

          if product.save
            attach_photos!(product)
            render json: { product: ProductSerializer.new(product, request: request, detailed: true).as_json }, status: :created
          else
            render json: { error: product.errors.full_messages.to_sentence }, status: :unprocessable_entity
          end
        end

        def update
          attributes = product_params
          photos = Array(attributes.delete(:photos)).compact_blank

          if photos.any?
            @product.update_column(:primary_photo_attachment_id, nil)
            @product.photos.purge
          end

          if @product.update(attributes.except(:photos))
            attach_photos!(@product, photos) if photos.any?
            render json: { product: ProductSerializer.new(@product.reload, request: request, detailed: true).as_json }
          else
            render json: { error: @product.errors.full_messages.to_sentence }, status: :unprocessable_entity
          end
        end

        def destroy
          @product.update_columns(status: "inactive", updated_at: Time.current)
          render json: { product: ProductSerializer.new(@product, request: request, detailed: true).as_json }
        end

        private

        def set_product
          @product = current_api_user.products.includes(photos_attachments: :blob).find(params[:id])
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

        def attach_photos!(product, photos = nil)
          uploads = photos || Array(params.dig(:product, :photos)).compact_blank
          return if uploads.blank?

          product.photos.attach(uploads)
          return if product.primary_photo_attachment_id.present?

          first_photo = product.photos.attachments.order(:created_at, :id).first
          product.update_column(:primary_photo_attachment_id, first_photo.id) if first_photo
        end
      end
    end
  end
end
