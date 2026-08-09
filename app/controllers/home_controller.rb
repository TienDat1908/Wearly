class HomeController < ApplicationController
  def index
    @featured_products = Product.active.includes(:owner, photos_attachments: :blob).order(created_at: :desc).limit(8)
    showcase_candidates = Product.active
      .joins(:photos_attachments)
      .distinct
      .includes(:owner, photos_attachments: :blob)
      .order(created_at: :desc)
      .limit(36)
      .to_a

    products_by_shop = showcase_candidates.group_by(&:owner_id).values
    largest_shop_size = products_by_shop.map(&:size).max.to_i
    shop_showcase_products = (0...largest_shop_size).flat_map do |product_index|
      products_by_shop.filter_map { |shop_products| shop_products[product_index] }
    end.first(18)

    animation_products = if shop_showcase_products.present? && shop_showcase_products.size < 9
      shop_showcase_products.cycle.take(9)
    else
      shop_showcase_products
    end

    @shop_showcase_columns = Array.new(3) { [] }
    animation_products.each_with_index do |product, index|
      @shop_showcase_columns[index % 3] << product
    end

    @home_spotlight = HomeSpotlight
      .with_attached_images
      .with_attached_image
      .active
      .first
    @active_products_count = Product.active.count
  end
end
