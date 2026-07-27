# frozen_string_literal: true

class ConversationsPairPerUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :conversations, :pair_key, :string
    add_column :messages, :booking_id, :bigint
    add_index :messages, :booking_id
    add_foreign_key :messages, :bookings, column: :booking_id, on_delete: :nullify

    say_with_time "backfill conversation pair_key" do
      execute <<~SQL.squish
        UPDATE conversations
        SET pair_key = CASE
          WHEN bookings.renter_id < bookings.owner_id
            THEN bookings.renter_id::text || ':' || bookings.owner_id::text
          ELSE bookings.owner_id::text || ':' || bookings.renter_id::text
        END
        FROM bookings
        WHERE conversations.kind = 'booking'
          AND conversations.booking_id = bookings.id
      SQL
    end

    say_with_time "merge duplicate pair conversations" do
      duplicate_keys = connection.select_values(<<~SQL.squish)
        SELECT pair_key
        FROM conversations
        WHERE kind = 'booking' AND pair_key IS NOT NULL
        GROUP BY pair_key
        HAVING COUNT(*) > 1
      SQL

      duplicate_keys.each do |key|
        ids = connection.select_values(
          ActiveRecord::Base.sanitize_sql_array([
            "SELECT id FROM conversations WHERE kind = 'booking' AND pair_key = ? ORDER BY id ASC",
            key
          ])
        ).map(&:to_i)
        keep_id = ids.first
        drop_ids = ids.drop(1)
        next if drop_ids.empty?

        drop_list = drop_ids.join(",")
        execute "UPDATE messages SET conversation_id = #{keep_id} WHERE conversation_id IN (#{drop_list})"
        execute "DELETE FROM conversation_participants WHERE conversation_id IN (#{drop_list})"
        execute "DELETE FROM conversations WHERE id IN (#{drop_list})"
      end
    end

    say_with_time "backfill message booking_id from conversation" do
      execute <<~SQL.squish
        UPDATE messages
        SET booking_id = conversations.booking_id
        FROM conversations
        WHERE messages.conversation_id = conversations.id
          AND messages.system = TRUE
          AND conversations.booking_id IS NOT NULL
      SQL
    end

    remove_index :conversations, name: "index_conversations_on_booking_id_unique"
    remove_foreign_key :conversations, :bookings if foreign_key_exists?(:conversations, :bookings)
    remove_column :conversations, :booking_id

    add_index :conversations,
      :pair_key,
      unique: true,
      where: "kind = 'booking' AND pair_key IS NOT NULL",
      name: "index_conversations_on_pair_key_unique"
  end

  def down
    add_reference :conversations, :booking, null: true, foreign_key: true, index: false
    add_index :conversations,
      :booking_id,
      unique: true,
      where: "booking_id IS NOT NULL",
      name: "index_conversations_on_booking_id_unique"

    remove_index :conversations, name: "index_conversations_on_pair_key_unique"
    remove_column :conversations, :pair_key

    remove_foreign_key :messages, column: :booking_id if foreign_key_exists?(:messages, column: :booking_id)
    remove_index :messages, :booking_id if index_exists?(:messages, :booking_id)
    remove_column :messages, :booking_id
  end
end
