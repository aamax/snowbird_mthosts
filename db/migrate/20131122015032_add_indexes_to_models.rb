class AddIndexesToModels < ActiveRecord::Migration
  def change
    add_index :users, :name

    add_index :shift_types, :short_name

    add_index :shifts, :shift_date
    add_index :shifts, :user_id
  end
end
