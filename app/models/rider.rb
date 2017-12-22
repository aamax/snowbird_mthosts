# == Schema Information
#
# Table name: riders
#
#  id             :integer          not null, primary key
#  host_hauler_id :integer
#  user_id        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Rider < ActiveRecord::Base
  belongs_to :host_hauler
  belongs_to :user
end
