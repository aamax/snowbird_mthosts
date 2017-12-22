class CreateRiders < ActiveRecord::Migration
  def change
    create_table :riders do |t|
      t.integer :host_hauler_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
