module Admin
  class DashboardController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!

    def index
      @users_count = User.count
      @owners_count = User.where(role: "owner").count
      @renters_count = User.where(role: "renter").count

      @products_count = Product.count
      @bookings_count = Booking.count
      @pending_bookings_count = Booking.where(status: "pending").count

      @gmv_amount = Booking.sum(:total_amount).to_i
      @owner_platform_fee_amount = Booking.sum(:platform_fee_amount).to_i
      @renter_service_fee_amount = Booking.column_names.include?("renter_service_fee_amount") ? Booking.sum(:renter_service_fee_amount).to_i : 0
      @platform_revenue_amount = @owner_platform_fee_amount + @renter_service_fee_amount
      @owner_payout_amount = Booking.sum(:owner_earning_amount).to_i
      @deposit_amount = Booking.sum(:deposit_amount).to_i

      @owner_platform_fee_rate = 15
      @renter_service_fee_rate = 5

      @latest_users = User.order(created_at: :desc).limit(5)
      @latest_products = Product.includes(:owner).order(created_at: :desc).limit(5)
      @latest_bookings = Booking.includes(:product, :owner, :renter).order(created_at: :desc).limit(5)
    end
  end
end
