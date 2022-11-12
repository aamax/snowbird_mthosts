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
        u = User.create(email: "driver#{number}@example.com", password: "password",
                        name: "name#{number}", active_user: true)

        u.add_role :driver
      end

      (1..10).each do |number|
        u = User.create(email: "rider#{number}@example.com", password: "password",
                        name: "rider#{number}", active_user: true)
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
      User.delete_all
      u = User.create(email: "unused_driver@example.com", password: "password",
                        name: "name1", active_user: true)
      u.add_role :driver

      h = host_hauler
      h.haul_date = Date.today()
      h.driver_id = u.id
      h.save
      rider = Rider.new
      h.riders << rider

      shift = Shift.all.first
      shift.user_id = u.id
      shift.save

      rider.can_select_rider(u).must_equal false
    end

    def test_cannot_pick_seat_if_not_working
      u = User.create(email: "unused_driver@example.com", password: "password",
                      name: "name1", active_user: true)

      h = host_hauler
      h.haul_date = Date.today()
      h.save
      rider = Rider.new
      h.riders << rider

      rider.can_select_rider(u).must_equal false
    end

    def test_can_pick_seat_if_working
      u = User.create(email: "unused_driver@example.com", password: "password",
                      name: "name1", active_user: true)

      h = host_hauler
      h.haul_date = Date.today()
      h.save
      rider = Rider.new
      h.riders << rider

      shift_type = ShiftType.find(2)
      shift = FactoryBot.create(:shift, shift_date: Date.today(), shift_type_id: shift_type.id)
      u.shifts << shift
      rider.can_select_rider(u).must_equal true
    end

    def test_cannot_pick_seat_if_just_meeting
      u = User.create(email: "unused_driver@example.com", password: "password",
                      name: "name1", active_user: true)

      h = host_hauler
      h.haul_date = Date.today()
      h.save
      rider = Rider.new
      h.riders << rider

      shift_type = ShiftType.find_by(short_name: 'M1')
      shift = FactoryBot.create(:shift, shift_date: Date.today(), shift_type_id: shift_type.id)
      u.shifts << shift
      rider.can_select_rider(u).must_equal false
    end

    def test_can_pick_seat_if_meeting_and_work
      u = User.create(email: "unused_driver@example.com", password: "password",
                      name: "name1", active_user: true)

      h = host_hauler
      h.haul_date = Date.today()
      h.save
      rider = Rider.new
      h.riders << rider

      shift_type = ShiftType.find_by(short_name: 'M1')
      shift = FactoryBot.create(:shift, shift_date: Date.today(), shift_type_id: shift_type.id)
      u.shifts << shift

      rider.can_select_rider(u).must_equal false

      shift_type = ShiftType.find(2)
      shift = FactoryBot.create(:shift, shift_date: Date.today(), shift_type_id: shift_type.id)
      u.shifts << shift

      rider.can_select_rider(u).must_equal true
    end

  end
end
