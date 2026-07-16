class CreateBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :bookings do |t|
      t.references :product, null: false, foreign_key: true
      t.bigint :owner_id
      t.bigint :renter_id
      t.string :status
      t.datetime :start_time
      t.datetime :end_time
      t.integer :rental_days
      t.integer :rental_amount
      t.integer :cleaning_fee
      t.integer :delivery_fee
      t.integer :deposit_amount
      t.integer :discount_amount
      t.decimal :platform_fee_rate
      t.integer :platform_fee_amount
      t.integer :owner_earning_amount
      t.integer :total_amount
      t.string :pickup_method
      t.text :pickup_address
      t.text :return_address
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :cancelled_at
      t.datetime :picked_up_at
      t.datetime :returned_at
      t.datetime :completed_at
      t.text :cancel_reason
      t.text :reject_reason

      t.timestamps
    end
  end
end
