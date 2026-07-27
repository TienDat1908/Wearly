# frozen_string_literal: true

class AddSystemToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :system, :boolean, null: false, default: false
    add_index :messages, [:conversation_id, :system]
  end
end
