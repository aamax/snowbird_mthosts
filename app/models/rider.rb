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

  def can_select_rider(user)
    self.user_id.nil? && user_not_in_hauler(user)
  end

  def can_drop_rider(user)
    (user.admin? && !self.user_id.nil?) || (!self.user_id.nil? && (user.id == self.user_id))
  end

  private

  def user_not_in_hauler(user)
    self.host_hauler.rider_not_riding(user)
  end
end
