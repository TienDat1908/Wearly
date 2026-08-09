# frozen_string_literal: true

module Owner
  class ProductAvailabilitiesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_owner!
    before_action :set_product

    def show
      @from = params[:from].present? ? Date.iso8601(params[:from]) : Date.current.beginning_of_month
      @to = params[:to].present? ? Date.iso8601(params[:to]) : (@from + 2.months).end_of_month
      @busy = Products::BusyRanges.call(
        product: @product,
        from: @from,
        to: @to,
        include_booking_details: true
      ).busy
      @blocked_dates = @product.product_blocked_dates.order(:start_on, :id)
      @blocked_date = @product.product_blocked_dates.new
    rescue ArgumentError, Date::Error
      redirect_to owner_product_availability_path(@product), alert: t("flash.bookings.unavailable")
    end

    private

    def set_product
      @product = current_user.products.includes(photos_attachments: :blob).find(params[:product_id])
    end
  end
end
