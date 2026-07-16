class CreatePromotions < ActiveRecord::Migration[7.2]
  def change
    create_table :promotions do |t|
      t.bigint :owner_id
      t.string :code
      t.string :discount_type
      t.decimal :discount_value
      t.integer :max_discount_amount
      t.integer :min_order_amount
      t.integer :usage_limit
      t.integer :used_count
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active

      t.timestamps
    end
  end
end
