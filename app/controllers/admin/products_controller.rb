module Admin
  class ProductsController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_product, only: [:show, :edit, :update]

    def index
      @products = Product.includes(:owner).order(created_at: :desc)
      @products = @products.where(status: params[:status]) if params[:status].present?
      @products = @products.where(product_type: params[:product_type]) if params[:product_type].present?
      @products = @products.search_by_keyword(params[:q]) if params[:q].present?
    end

    def show
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: t("flash.admin.products.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_product
      @product = Product.includes(:owner, photos_attachments: :blob).find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :title,
        :product_type,
        :description,
        :status,
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
        :delivery_available
      )
    end
  end
end
