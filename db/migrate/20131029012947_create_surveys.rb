class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.integer     :user_id
      t.datetime    :date
      t.integer     :count
      t.integer     :survey_type
      t.timestamps
    end
  end
end
