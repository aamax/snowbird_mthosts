class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.integer     :user_id
      t.datetime    :date
      t.integer     :count
      t.integer     :type1
      t.integer     :type2
      t.timestamps
    end
  end
end
