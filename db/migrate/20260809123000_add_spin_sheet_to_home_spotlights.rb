class AddSpinSheetToHomeSpotlights < ActiveRecord::Migration[7.2]
  def change
    add_column :home_spotlights, :spin_frame_count, :integer, null: false, default: 5
  end
end
