# == Schema Information
#
# Table name: host_haulers
#
#  id         :integer          not null, primary key
#  driver_id  :integer
#  haul_date  :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class HostHauler < ActiveRecord::Base
  has_many :riders
  has_many :users, through: :riders

  def driver
    User.find_by(id: driver_id)
  end
end
