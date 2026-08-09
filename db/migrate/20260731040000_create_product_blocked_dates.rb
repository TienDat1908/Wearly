# frozen_string_literal: true

class CreateProductBlockedDates < ActiveRecord::Migration[7.2]
  def change
    create_table :product_blocked_dates do |t|
      t.references :product, null: false, foreign_key: true
      t.date :start_on, null: false
      t.date :end_on, null: false
      t.string :note
      t.timestamps
    end

    add_index :product_blocked_dates, [:product_id, :start_on, :end_on],
      name: "index_product_blocked_dates_on_product_and_range"
  end
end
