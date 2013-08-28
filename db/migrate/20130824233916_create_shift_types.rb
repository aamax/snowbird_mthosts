class CreateShiftTypes < ActiveRecord::Migration
  def change
    create_table :shift_types do |t|
      t.string        :short_name, :null => false
      t.string        :description, :null => false
      t.string        :start_time
      t.string        :end_time
      t.string        :tasks

      t.timestamps
    end
  end
end
