class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @products = @user.products.active.includes(photos_attachments: :blob).order(created_at: :desc).limit(8)
    @shared_booking = shared_booking_with(@user)
  end

  private

  def shared_booking_with(user)
    return unless user_signed_in?
    return if current_user.id == user.id

    Booking
      .where(
        "(renter_id = :current_user_id AND owner_id = :user_id) OR (renter_id = :user_id AND owner_id = :current_user_id)",
        current_user_id: current_user.id,
        user_id: user.id
      )
      .order(created_at: :desc)
      .first
  end
end
