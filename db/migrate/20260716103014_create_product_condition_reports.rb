class CreateProductConditionReports < ActiveRecord::Migration[7.2]
  def change
    create_table :product_condition_reports do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :report_type
      t.string :status
      t.text :note

      t.timestamps
    end
  end
end
