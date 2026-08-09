# frozen_string_literal: true

module Owner
  class ProductBlockedDatesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_owner!
    before_action :set_product
    before_action :set_blocked_date, only: [:destroy]

    def create
      @blocked_date = @product.product_blocked_dates.new(blocked_date_params)

      if @blocked_date.save
        redirect_to owner_product_availability_path(@product, from: @blocked_date.start_on.beginning_of_month),
          notice: t("flash.owner.blocked_dates.created")
      else
        redirect_to owner_product_availability_path(@product),
          alert: @blocked_date.errors.full_messages.to_sentence
      end
    end

    def destroy
      month = @blocked_date.start_on.beginning_of_month
      @blocked_date.destroy!
      redirect_to owner_product_availability_path(@product, from: month),
        notice: t("flash.owner.blocked_dates.deleted")
    end

    private

    def set_product
      @product = current_user.products.find(params[:product_id])
    end

    def set_blocked_date
      @blocked_date = @product.product_blocked_dates.find(params[:id])
    end

    def blocked_date_params
      params.require(:product_blocked_date).permit(:start_on, :end_on, :note)
    end
  end
end
