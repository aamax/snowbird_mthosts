class AddSnowbirdStartYearToUser < ActiveRecord::Migration
  def change
    add_column :users, :snowbird_start_year,     :integer
  end
end
