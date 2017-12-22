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

require "test_helper"

class RiderTest < ActiveSupport::TestCase
  def rider
    @rider ||= Rider.new
  end

  def test_valid
    assert rider.valid?
  end
end
