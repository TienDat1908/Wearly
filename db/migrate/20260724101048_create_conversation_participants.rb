class CreateConversationParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :conversation_participants do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :last_read_at

      t.timestamps
    end

    add_index :conversation_participants, [:conversation_id, :user_id], unique: true, name: "index_conversation_participants_uniqueness"
    add_index :conversation_participants, [:user_id, :conversation_id], name: "index_conversation_participants_on_user_and_conversation"
  end
end
