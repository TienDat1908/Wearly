class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.bigint :owner_id
      t.string :title
      t.string :product_type
      t.text :description
      t.string :status
      t.string :condition_status
      t.string :size
      t.string :color
      t.string :gender
      t.string :age_group
      t.string :brand
      t.integer :price_per_day
      t.integer :deposit_amount
      t.integer :cleaning_fee
      t.integer :replacement_value
      t.text :address
      t.string :city
      t.string :district
      t.string :ward
      t.boolean :pickup_available
      t.boolean :delivery_available
      t.jsonb :details

      t.timestamps
    end
  end
end
