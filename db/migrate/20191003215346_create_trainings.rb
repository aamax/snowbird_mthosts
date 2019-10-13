class CreateTrainings < ActiveRecord::Migration
  def change
    create_table :ongoing_trainings do |t|
      t.integer :user_id
      t.integer :training_date_id
      t.boolean :is_trainer

      t.timestamps null: false
    end
  end
end
