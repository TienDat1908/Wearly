module Owner
  class ProductsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_owner!
    before_action :set_product, only: [:edit, :update, :destroy]

    def index
      @products = current_user.products.order(created_at: :desc)
    end

    def new
      @product = current_user.products.new
    end

    def create
      @product = current_user.products.new(product_params)
      @product.status = "active"

      if @product.save
        redirect_to owner_products_path, notice: t("flash.products.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to owner_products_path, notice: t("flash.products.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to owner_products_path, notice: t("flash.products.deleted")
    end

    private

    def set_product
      @product = current_user.products.find(params[:id])
    end

    def require_owner!
      return if current_user.owner? || current_user.admin?

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
        photos: []
      )
    end
  end
end
