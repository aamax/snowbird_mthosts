class CreateShiftLogs < ActiveRecord::Migration
  def change
    create_table :shift_logs do |t|
      t.datetime :change_date
      t.integer :user_id
      t.integer :shift_id
      t.string :action_taken
      t.text :note

      t.timestamps null: false
    end
  end
end
