class AddIndexesAndForeignKeysForWearly < ActiveRecord::Migration[7.2]
  def change
    add_index :users, :phone, unique: true
    add_index :users, :role
    add_index :users, :status
    add_index :users, :preferred_locale

    add_index :products, :owner_id
    add_index :products, :product_type
    add_index :products, :status
    add_index :products, :city
    add_foreign_key :products, :users, column: :owner_id

    add_index :bookings, :owner_id
    add_index :bookings, :renter_id
    add_index :bookings, :status
    add_index :bookings, [:product_id, :start_time, :end_time]
    add_foreign_key :bookings, :users, column: :owner_id
    add_foreign_key :bookings, :users, column: :renter_id

    add_index :product_reservations, :renter_id
    add_index :product_reservations, :status
    add_index :product_reservations, [:product_id, :start_time, :end_time]
    add_foreign_key :product_reservations, :users, column: :renter_id

    add_index :payments, :payer_id
    add_index :payments, :status
    add_foreign_key :payments, :users, column: :payer_id

    add_index :payouts, :owner_id
    add_index :payouts, :status
    add_foreign_key :payouts, :users, column: :owner_id

    add_index :promotions, :owner_id
    add_index :promotions, :code, unique: true
    add_foreign_key :promotions, :users, column: :owner_id

    add_index :disputes, :opened_by_id
    add_index :disputes, :resolved_by_id
    add_index :disputes, :status
    add_foreign_key :disputes, :users, column: :opened_by_id
    add_foreign_key :disputes, :users, column: :resolved_by_id

    add_index :reviews, :reviewer_id
    add_index :reviews, :reviewee_id
    add_foreign_key :reviews, :users, column: :reviewer_id
    add_foreign_key :reviews, :users, column: :reviewee_id
  end
end
