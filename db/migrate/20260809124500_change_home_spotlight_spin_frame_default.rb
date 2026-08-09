class ChangeHomeSpotlightSpinFrameDefault < ActiveRecord::Migration[7.2]
  def change
    change_column_default :home_spotlights, :spin_frame_count, from: 5, to: 1
  end
end
