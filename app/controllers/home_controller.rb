class HomeController < ApplicationController
  def index
    @featured_products = Product.active.includes(:owner).order(created_at: :desc).limit(8)
  end
end
