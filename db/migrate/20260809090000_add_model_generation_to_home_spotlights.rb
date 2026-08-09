class AddModelGenerationToHomeSpotlights < ActiveRecord::Migration[7.2]
  def change
    change_table :home_spotlights, bulk: true do |t|
      t.string :model_generation_status, null: false, default: "idle"
      t.text :model_generation_error
      t.datetime :model_generation_started_at
      t.datetime :model_generation_finished_at
    end
  end
end
