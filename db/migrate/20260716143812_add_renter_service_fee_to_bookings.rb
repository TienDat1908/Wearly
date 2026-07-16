class AddRenterServiceFeeToBookings < ActiveRecord::Migration[7.2]
  def change
    add_column :bookings, :renter_service_fee_rate, :decimal
    add_column :bookings, :renter_service_fee_amount, :integer
  end
end
