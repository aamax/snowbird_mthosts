class AddShiftCountToSysConfig < ActiveRecord::Migration
  def change
    add_column :sys_configs, :shift_count,     :integer
  end
end
