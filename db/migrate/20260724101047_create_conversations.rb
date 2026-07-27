class CreateConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations do |t|
      t.string :kind, null: false
      t.references :booking, null: true, foreign_key: true, index: false
      t.string :subject
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, :kind
    add_index :conversations, :last_message_at
    add_index :conversations,
      :booking_id,
      unique: true,
      where: "booking_id IS NOT NULL",
      name: "index_conversations_on_booking_id_unique"
  end
end
