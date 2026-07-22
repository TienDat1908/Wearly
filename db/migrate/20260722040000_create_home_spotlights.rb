class CreateHomeSpotlights < ActiveRecord::Migration[7.2]
  def change
    create_table :home_spotlights do |t|
      t.references :product, null: true, foreign_key: true
      t.string :eyebrow, null: false, default: "Featured pick"
      t.string :title, null: false, default: "Ready for tonight"
      t.string :subtitle
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 1

      t.timestamps
    end
  end
end
