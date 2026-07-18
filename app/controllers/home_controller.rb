class HomeController < ApplicationController
  def index
    @featured_products = Product.active.includes(:owner, photos_attachments: :blob).order(created_at: :desc).limit(8)
    @hero_products = @featured_products.first(3)
    @active_products_count = Product.active.count
  end
end
