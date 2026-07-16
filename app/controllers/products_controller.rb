class ProductsController < ApplicationController
  def index
    @products = Product.active.includes(:owner).order(created_at: :desc)

    @products = @products.search_by_keyword(params[:q]) if params[:q].present?
    @products = @products.where(product_type: params[:product_type]) if params[:product_type].present?
    @products = @products.where(city: params[:city]) if params[:city].present?
  end

  def show
    @product = Product.active.find(params[:id])
  end
end
