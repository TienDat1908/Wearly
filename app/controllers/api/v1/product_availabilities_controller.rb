# frozen_string_literal: true

module Api
  module V1
    class ProductAvailabilitiesController < BaseController
      def show
        product = Product.active.find(params[:product_id])
        from, to = parse_window

        result = Products::BusyRanges.call(
          product: product,
          from: from,
          to: to,
          include_booking_details: false
        )

        render json: {
          product_id: product.id,
          from: result.from.iso8601,
          to: result.to.iso8601,
          busy: result.busy
        }
      rescue ArgumentError
        render json: { error: "Please choose a valid date range.", code: "invalid_date_range" }, status: :unprocessable_entity
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found.", code: "not_found" }, status: :not_found
      end

      private

      def parse_window
        from = params[:from].present? ? Date.iso8601(params[:from]) : Date.current.beginning_of_month
        to = params[:to].present? ? Date.iso8601(params[:to]) : (from + 2.months).end_of_month
        raise ArgumentError if to < from || (to - from).to_i > 366

        [from, to]
      end
    end
  end
end
