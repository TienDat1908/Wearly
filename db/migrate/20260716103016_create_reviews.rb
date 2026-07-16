class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :booking, null: false, foreign_key: true
      t.bigint :reviewer_id
      t.bigint :reviewee_id
      t.references :product, null: false, foreign_key: true
      t.integer :rating
      t.text :comment

      t.timestamps
    end
  end
end
