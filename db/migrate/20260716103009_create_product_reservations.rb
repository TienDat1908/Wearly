class CreateProductReservations < ActiveRecord::Migration[7.2]
  def change
    create_table :product_reservations do |t|
      t.references :product, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.bigint :renter_id
      t.datetime :start_time
      t.datetime :end_time
      t.string :status
      t.string :reason

      t.timestamps
    end
  end
end
