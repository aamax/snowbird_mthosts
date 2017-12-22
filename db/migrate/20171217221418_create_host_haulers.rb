class CreateHostHaulers < ActiveRecord::Migration
  def change
    create_table :host_haulers do |t|
      t.integer :driver_id
      t.date :haul_date

      t.timestamps null: false
    end
  end
end
