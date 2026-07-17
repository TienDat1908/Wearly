module Admin
  class PayoutsController < ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :require_admin!
    before_action :set_payout, only: [:show, :update]

    def index
      @payouts = Payout
        .includes(:owner, booking: [:product, :renter])
        .order(created_at: :desc)

      @payouts = @payouts.where(status: params[:status]) if params[:status].present?
    end

    def show
    end

    def update
      if @payout.pending?
        @payout.update!(
          status: "paid",
          paid_at: Time.current,
          payout_method: @payout.payout_method.presence || "manual",
          admin_note: payout_params[:admin_note].presence || @payout.admin_note
        )

        redirect_to admin_payout_path(@payout), notice: t("flash.admin.payouts.paid")
      else
        redirect_to admin_payout_path(@payout), alert: t("flash.admin.payouts.invalid_status")
      end
    end

    private

    def set_payout
      @payout = Payout
        .includes(:owner, booking: [:product, :renter])
        .find(params[:id])
    end

    def payout_params
      params.fetch(:payout, {}).permit(:admin_note)
    end
  end
end
