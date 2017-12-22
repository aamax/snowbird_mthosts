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

require "test_helper"

class HostHaulerTest < ActiveSupport::TestCase
  def host_hauler
    @host_hauler ||= HostHauler.new
  end

  def test_valid
    assert host_hauler.valid?
  end
end
