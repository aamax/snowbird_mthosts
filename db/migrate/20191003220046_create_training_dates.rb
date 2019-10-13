class CreateTrainingDates < ActiveRecord::Migration
  def change
    create_table :training_dates do |t|
      t.date :shift_date

      t.timestamps null: false
    end
  end
end
