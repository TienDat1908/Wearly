module Owner
  class BookingsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_owner!
    before_action :set_booking, only: [:show, :accept, :reject, :complete, :chat]

    def index
      @bookings = current_user
        .owner_bookings
        .includes(:product, renter: { avatar_attachment: :blob })
        .order(created_at: :desc)

      @bookings.pending.find_each(&:expire_if_acceptance_timed_out!)
      @bookings = @bookings.reload
    end

    def show
    end

    def accept
      @booking.expire_if_acceptance_timed_out!

      unless @booking.pending?
        redirect_to owner_booking_path(@booking), alert: acceptance_blocked_alert
        return
      end

      ActiveRecord::Base.transaction do
        @booking.accept!
        @booking.update!(accepted_at: Time.current)
        @booking.product_reservation&.update!(status: "confirmed")
        Conversations::EnsureBooking.call(booking: @booking)
      end

      redirect_to owner_bookings_path, notice: t("flash.bookings.accepted")
    end

    def reject
      @booking.expire_if_acceptance_timed_out!

      unless @booking.pending?
        redirect_to owner_booking_path(@booking), alert: acceptance_blocked_alert
        return
      end

      ActiveRecord::Base.transaction do
        @booking.reject!
        @booking.update!(rejected_at: Time.current)
        @booking.product_reservation&.update!(status: "cancelled")
      end

      redirect_to owner_bookings_path, notice: t("flash.bookings.rejected")
    end

    def complete
      unless @booking.completable?
        redirect_to owner_booking_path(@booking), alert: t("flash.bookings.cannot_complete_yet")
        return
      end

      ActiveRecord::Base.transaction do
        @booking.complete!
        @booking.update!(returned_at: Time.current, completed_at: Time.current)
        @booking.product_reservation&.update!(status: "cancelled")

        Payout.find_or_create_by!(booking: @booking) do |payout|
          payout.owner_id = @booking.owner_id
          payout.amount = @booking.owner_earning_amount.to_i
          payout.status = "pending"
          payout.payout_method = "manual"
        end
      end

      redirect_to owner_bookings_path, notice: t("flash.bookings.completed")
    end

    def chat
      unless @booking.chattable?
        redirect_to owner_booking_path(@booking), alert: t("flash.conversations.booking_chat_unavailable")
        return
      end

      conversation = Conversations::EnsureBooking.call(booking: @booking)
      redirect_to conversation_path(conversation)
    end

    private

    def set_booking
      @booking = current_user
        .owner_bookings
        .includes(:product, renter: { avatar_attachment: :blob })
        .find(params[:id])
      @booking.expire_if_acceptance_timed_out!
    end

    def acceptance_blocked_alert
      if @booking.acceptance_timed_out?
        t("flash.bookings.acceptance_expired")
      else
        t("flash.bookings.invalid_status")
      end
    end
  end
end
