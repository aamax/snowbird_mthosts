class CreateSysConfigs < ActiveRecord::Migration
  def change
    create_table :sys_configs do |t|
      t.integer :season_year
      t.integer :group_1_year
      t.integer :group_2_year
      t.integer :group_3_year
      t.date    :season_start_date
      t.date    :bingo_start_date
      t.timestamps
    end
  end
end
