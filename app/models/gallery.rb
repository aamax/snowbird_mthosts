# == Schema Information
#
# Table name: galleries
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  category         :string(255)      default("general")
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pic_file_name    :string(255)
#  pic_content_type :string(255)
#  pic_file_size    :integer
#  pic_updated_at   :datetime
#

class Gallery < ActiveRecord::Base
  attr_accessible :name, :user_id, :pic

  validates_presence_of :name

  belongs_to :user

  has_attached_file :pic, styles: {
      thumb: '100x100>',
      square: '200x200#',
      medium: '300x300>',
      large:  '1024x1024>'
  }
end
