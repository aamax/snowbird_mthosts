class AddPicToGalleries < ActiveRecord::Migration
  def self.up
    add_attachment :galleries, :pic
  end

  def self.down
    remove_attachment :galleries, :pic
  end

end
