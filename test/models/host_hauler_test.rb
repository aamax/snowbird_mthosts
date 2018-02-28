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

  describe "eligibility tests" do
    def setup
      User.delete_all
      (1..3).each do |number|
        u = User.create(email: "driver#{number}@example.com", password: "password", name: "name#{number}")

        u.add_role :driver
      end

      (1..10).each do |number|
        u = User.create(email: "rider#{number}@example.com", password: "password", name: "rider#{number}")
      end
      assert_equal(13, User.all.count)

      @driver = User.with_role(:driver).first
      dt = Date.today

      @riders = []

      @hauler = HostHauler.create(driver_id: @driver.id, haul_date: dt)
      (1..14).each do |host|
        r = Rider.create(host_hauler_id: @hauler.id)
        @riders << r
      end
    end

    def test_eligible_riders_empty_hauler
      eligible_riders = @hauler.eligible_riders
      assert_equal(12, eligible_riders.count)
    end

    def test_eligible_riders_some_riders
      rider_seats = []
      (0..4).each do |n|
        rider_seats << @riders[n]
      end
      eligibles = @hauler.eligible_riders[0..4]

      (0..4).each do |n|
        @hauler.riders[n].user_id = eligibles[n].id
        @hauler.riders[n].save
      end

      eligible_riders = @hauler.eligible_riders
      assert_equal(7, eligible_riders.count)
    end

    def test_eligible_drivers
      drivers = @hauler.eligible_drivers
      assert_equal(3, drivers.count)
      (1..3).each do |number|
        email = "driver#{number}@example.com"
        d = User.find_by(email: email)
        assert_equal(true, drivers.include?(d))
      end
    end

    def test_cannot_ride_if_driving

    end
  end
end
