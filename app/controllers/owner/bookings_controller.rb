module Owner
  class BookingsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_owner!
    before_action :set_booking, only: [:show, :accept, :reject, :complete]

    def index
      @bookings = current_user
        .owner_bookings
        .includes(:product, :renter)
        .order(created_at: :desc)
    end

    def show
    end

    def accept
      unless @booking.pending?
        redirect_to owner_booking_path(@booking), alert: t("flash.bookings.invalid_status")
        return
      end

      ActiveRecord::Base.transaction do
        @booking.accept!
        @booking.product_reservation&.update!(status: "confirmed")
      end

      redirect_to owner_bookings_path, notice: t("flash.bookings.accepted")
    end

    def reject
      unless @booking.pending?
        redirect_to owner_booking_path(@booking), alert: t("flash.bookings.invalid_status")
        return
      end

      ActiveRecord::Base.transaction do
        @booking.reject!
        @booking.product_reservation&.update!(status: "cancelled")
      end

      redirect_to owner_bookings_path, notice: t("flash.bookings.rejected")
    end

    def complete
      unless @booking.paid?
        redirect_to owner_booking_path(@booking), alert: t("flash.bookings.must_be_paid_first")
        return
      end

      ActiveRecord::Base.transaction do
        @booking.complete!

        Payout.find_or_create_by!(booking: @booking) do |payout|
          payout.owner_id = @booking.owner_id
          payout.amount = @booking.owner_earning_amount.to_i
          payout.status = "pending"
          payout.payout_method = "manual"
        end
      end

      redirect_to owner_bookings_path, notice: t("flash.bookings.completed")
    end

    private

    def set_booking
      @booking = current_user.owner_bookings.find(params[:id])
    end
  end
end
