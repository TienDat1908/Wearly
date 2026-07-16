class CreateDisputes < ActiveRecord::Migration[7.2]
  def change
    create_table :disputes do |t|
      t.references :booking, null: false, foreign_key: true
      t.bigint :opened_by_id
      t.string :reason
      t.text :description
      t.string :status
      t.text :resolution_note
      t.bigint :resolved_by_id
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
