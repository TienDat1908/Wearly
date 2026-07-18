module Api
  module V1
    class ProductsController < BaseController
      def index
        products = Product.active
          .includes(:owner, photos_attachments: :blob)
          .order(created_at: :desc)

        products = products.search_by_keyword(params[:q]) if params[:q].present?
        products = products.where(product_type: params[:product_type]) if params[:product_type].present?
        products = products.where(city: params[:city]) if params[:city].present?

        render json: {
          products: products.map { |product| ProductSerializer.new(product, request: request).as_json }
        }
      end

      def show
        product = Product.active
          .includes(owner: { avatar_attachment: :blob }, photos_attachments: :blob)
          .find(params[:id])

        render json: {
          product: ProductSerializer.new(product, request: request, detailed: true).as_json
        }
      end
    end
  end
end
