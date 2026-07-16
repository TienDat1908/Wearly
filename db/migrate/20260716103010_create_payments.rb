class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: true
      t.bigint :payer_id
      t.integer :amount
      t.string :payment_method
      t.string :status
      t.string :transaction_id
      t.datetime :paid_at
      t.text :admin_note

      t.timestamps
    end
  end
end
