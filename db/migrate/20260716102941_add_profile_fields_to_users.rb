class AddProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :full_name, :string
    add_column :users, :phone, :string
    add_column :users, :role, :string
    add_column :users, :status, :string
    add_column :users, :preferred_locale, :string
    add_column :users, :address, :text
    add_column :users, :city, :string
    add_column :users, :district, :string
    add_column :users, :ward, :string
    add_column :users, :facebook_url, :string
    add_column :users, :instagram_url, :string
    add_column :users, :tiktok_url, :string
    add_column :users, :zalo_url, :string
    add_column :users, :website_url, :string
    add_column :users, :bank_name, :string
    add_column :users, :bank_account_name, :string
    add_column :users, :bank_account_number, :string
  end
end
