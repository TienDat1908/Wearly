class HomeController < ApplicationController
  def index
    @featured_products = Product.active.includes(:owner, photos_attachments: :blob).order(created_at: :desc).limit(8)
    @hero_products = @featured_products.first(3)
    @home_spotlight = HomeSpotlight.with_attached_images.with_attached_image.active.first
    @active_products_count = Product.active.count
  end
end
