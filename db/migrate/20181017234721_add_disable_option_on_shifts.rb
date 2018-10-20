class AddDisableOptionOnShifts < ActiveRecord::Migration
  def change
    add_column :shifts, :disabled, :boolean
  end
end
