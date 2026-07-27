class ProductsController < ApplicationController
  def index
    @products = Product.active.includes(:owner, photos_attachments: :blob).order(created_at: :desc)

    @products = @products.search_by_keyword(params[:q]) if params[:q].present?
    @products = @products.where(product_type: params[:product_type]) if params[:product_type].present?
    @products = @products.where(city: params[:city]) if params[:city].present?
  end

  def show
    @product = Product.active.includes(owner: { avatar_attachment: :blob }, photos_attachments: :blob).find(params[:id])
    @chat_booking = chattable_booking_for_product(@product)
  end

  private

  def chattable_booking_for_product(product)
    return unless user_signed_in?
    return if current_user.id == product.owner_id

    current_user
      .rentals
      .where(product_id: product.id, status: Booking::CHATTABLE_STATUSES)
      .order(created_at: :desc)
      .first
  end
end
