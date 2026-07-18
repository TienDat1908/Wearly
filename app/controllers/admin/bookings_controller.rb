module Admin
  class BookingsController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_booking, only: [:show, :edit, :update]

    def index
      @bookings = Booking.includes(:product, :owner, :renter, :payment, :product_reservation, :payout).order(created_at: :desc)
      @bookings = @bookings.where(status: params[:status]) if params[:status].present?
    end

    def show
    end

    def edit
    end

    def update
      if @booking.update(booking_params)
        redirect_to admin_booking_path(@booking), notice: t("flash.admin.bookings.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_booking
      @booking = Booking.includes(:owner, :renter, :payment, :product_reservation, :payout, product: [:owner, photos_attachments: :blob]).find(params[:id])
    end

    def booking_params
      params.require(:booking).permit(
        :cancel_reason,
        :reject_reason
      )
    end
  end
end
