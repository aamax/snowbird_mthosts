class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :street,     :string
    add_column :users, :city,       :string
    add_column :users, :state,      :string
    add_column :users, :zip,        :string
    add_column :users, :home_phone, :string
    add_column :users, :cell_phone, :string
    add_column :users, :alt_email,  :string
    add_column :users, :start_year, :integer
    add_column :users, :notes,      :text
    add_column :users, :confirmed,  :boolean
    add_column :users, :active_user,:boolean
    add_column :users, :nickname,   :string
  end
end
