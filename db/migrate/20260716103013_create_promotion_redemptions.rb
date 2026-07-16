class CreatePromotionRedemptions < ActiveRecord::Migration[7.2]
  def change
    create_table :promotion_redemptions do |t|
      t.references :promotion, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.integer :discount_amount

      t.timestamps
    end
  end
end
