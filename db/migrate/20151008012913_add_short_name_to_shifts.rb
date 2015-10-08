class AddShortNameToShifts < ActiveRecord::Migration
  def change
    add_column :shifts, :short_name,     :string
  end
end
