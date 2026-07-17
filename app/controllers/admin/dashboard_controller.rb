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

      revenue_bookings = Booking.revenue_recognized

      @gmv_amount = revenue_bookings.sum(:total_amount).to_i
      @owner_platform_fee_amount = revenue_bookings.sum(:platform_fee_amount).to_i

      @renter_service_fee_amount =
        if Booking.column_names.include?("renter_service_fee_amount")
          revenue_bookings.sum(:renter_service_fee_amount).to_i
        else
          0
        end

      @platform_revenue_amount =
        @owner_platform_fee_amount + @renter_service_fee_amount

      @owner_payout_amount = revenue_bookings.sum(:owner_earning_amount).to_i
      @deposit_amount = revenue_bookings.sum(:deposit_amount).to_i

      @owner_platform_fee_rate = Booking::OWNER_PLATFORM_FEE_RATE
      @renter_service_fee_rate = Booking::RENTER_SERVICE_FEE_RATE

      @latest_users = User.order(created_at: :desc).limit(5)

      @latest_products = Product
        .includes(:owner)
        .order(created_at: :desc)
        .limit(5)

      @latest_bookings = Booking
        .includes(:product, :owner, :renter)
        .order(created_at: :desc)
        .limit(5)
    end
  end
end
