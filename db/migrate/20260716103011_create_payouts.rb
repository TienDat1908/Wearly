class CreatePayouts < ActiveRecord::Migration[7.2]
  def change
    create_table :payouts do |t|
      t.bigint :owner_id
      t.references :booking, null: false, foreign_key: true
      t.integer :amount
      t.string :status
      t.string :payout_method
      t.datetime :paid_at
      t.text :admin_note

      t.timestamps
    end
  end
end
