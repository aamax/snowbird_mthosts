class AddHeadShotToUser < ActiveRecord::Migration
  def change
    add_column :users, :head_shot,     :string
  end
end
