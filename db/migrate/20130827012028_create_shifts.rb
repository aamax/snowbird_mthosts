class CreateShifts < ActiveRecord::Migration
  def change
    create_table :shifts do |t|
      t.integer         :user_id
      t.integer         :shift_type_id, :null => false
      t.integer         :shift_status_id, :null => false, :default => 1
      t.date            :shift_date
      t.string          :day_of_week

      t.timestamps
    end
  end
end
