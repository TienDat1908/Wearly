module Owner
  class BookingsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_owner!

    def index
      @bookings = current_user.owner_bookings.includes(:product, :renter).order(created_at: :desc)
    end
  end
end
