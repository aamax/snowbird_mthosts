class CreateGalleries < ActiveRecord::Migration
  def change
    create_table :galleries do |t|
      t.string           :name
      t.string           :category, :default => 'general'
      t.integer          :user_id

      t.timestamps
    end
  end
end
