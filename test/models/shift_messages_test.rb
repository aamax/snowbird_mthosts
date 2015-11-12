require "test_helper"

class UserMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @group1_user = User.find_by_name('g1')
    @group2_user = User.find_by_name('g2')
    @group3_user = User.find_by_name('g3')
    @p1 = ShiftType.find_by_short_name('P1')
  end

  def test_show_need_a_holiday_if_not_picked
    [@group1_user, @group2_user, @group3_user].each do |u|
      u.has_holiday_shift?.must_equal false
      u.shift_status_message.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
    end
  end

  def test_show_need_a_holiday_if_picked
    [@group1_user, @group2_user, @group3_user].each do |u|
      HOLIDAYS.each do |h|
        shift = FactoryGirl.create(:shift, shift_date: h, shift_type_id: @p1.id)

        u.shifts << shift
        u.has_holiday_shift?.must_equal true
        u.shift_status_message.include?("A <strong>Holiday Shift</strong> has been selected.").must_equal true
      end
    end
  end

  def test_shift_picking_before_round_one
    config = SysConfig.first
    config.bingo_start_date = Date.today + 10.days
    config.save

    @group1_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group1_user, 1)}.").must_equal true
    @group2_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group2_user, 1)}.").must_equal true
    @group3_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group3_user, 1)}.").must_equal true
  end

  def test_report_shift_count_after_selection_rounds
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
    config.save

    @group1_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
    @group2_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
    @group3_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
  end

  def test_show_selection_counts_for_round_one_trainers
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 1)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    @group1_user.add_role("trainer")

    trshift = FactoryGirl.create(:shift_type, short_name: 'TR')
    trshifts = []
    (1..5).each do |n|
      trshifts << FactoryGirl.create(:shift, shift_type_id: trshift.id, user_id: @group1_user.id,
                                     shift_date: Date.today + 4.months + n.days, short_name: 'TR')
    end

    maxshifts = 12
    shifts.each do |s|
        break if @group1_user.shifts.length >= maxshifts
        if @group1_user.shifts.length < maxshifts
          @group1_user.shift_status_message.include?("#{@group1_user.shifts.length} of #{maxshifts} Shifts Selected.  You need to pick #{maxshifts - @group1_user.shifts.length}").must_equal true
        else
          @group1_user.shift_status_message.include?("All required shifts selected for round 1. (#{maxshifts} of #{maxshifts})").must_equal true
        end
        @group1_user.shifts << s
    end
  end

  def test_show_selection_counts_for_round_two_trainers
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    @group1_user.add_role("trainer")

    trshift = FactoryGirl.create(:shift_type, short_name: 'TR')
    trshifts = []
    (1..5).each do |n|
      trshifts << FactoryGirl.create(:shift, shift_type_id: trshift.id, user_id: @group1_user.id,
                                     shift_date: Date.today + 4.months + n.days, short_name: 'TR')
    end

    maxshifts = 17
    shifts.each do |s|
      break if @group1_user.shifts.length >= maxshifts
      if @group1_user.shifts.length < maxshifts
        @group1_user.shift_status_message.include?("#{@group1_user.shifts.length} of #{maxshifts} Shifts Selected.  You need to pick #{maxshifts - @group1_user.shifts.length}").must_equal true
      else
        @group1_user.shift_status_message.include?("All required shifts selected for round 1. (#{maxshifts} of #{maxshifts})").must_equal true
      end
      @group1_user.shifts << s
    end

  end

  def test_show_selection_counts_for_round_three_trainers
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    @group1_user.add_role("trainer")

    trshift = FactoryGirl.create(:shift_type, short_name: 'TR')
    trshifts = []
    (1..5).each do |n|
      trshifts << FactoryGirl.create(:shift, shift_type_id: trshift.id, user_id: @group1_user.id,
                                     shift_date: Date.today + 4.months + n.days, short_name: 'TR')
    end

    maxshifts = 20
    shifts.each do |s|
      break if @group1_user.shifts.length >= maxshifts
      if @group1_user.shifts.length < maxshifts
        @group1_user.shift_status_message.include?("#{@group1_user.shifts.length} of #{maxshifts} Shifts Selected.  You need to pick #{maxshifts - @group1_user.shifts.length}").must_equal true
      else
        @group1_user.shift_status_message.include?("All required shifts selected for round 1. (#{maxshifts} of #{maxshifts})").must_equal true
      end
      @group1_user.shifts << s
    end

  end

  def test_show_selection_counts_for_round_four_trainers
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    @group1_user.add_role("trainer")

    trshift = FactoryGirl.create(:shift_type, short_name: 'TR')
    trshifts = []
    (1..5).each do |n|
      trshifts << FactoryGirl.create(:shift, shift_type_id: trshift.id, user_id: @group1_user.id,
                                     shift_date: Date.today + 4.months + n.days, short_name: 'TR')
    end

    maxshifts = 20
    shifts.each do |s|
      break if @group1_user.shifts.length >= maxshifts
      if @group1_user.shifts.length < maxshifts
        @group1_user.shift_status_message.include?("#{@group1_user.shifts.length} of #{maxshifts} Shifts Selected.  You need to pick #{maxshifts - @group1_user.shifts.length}").must_equal true
      else
        @group1_user.shift_status_message.include?("All required shifts selected for round 1. (#{maxshifts} of #{maxshifts})").must_equal true
      end
      @group1_user.shifts << s
    end

  end

  def test_show_selection_counts_for_round_one
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 1)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        break if u.shifts.length > 7
        if u.shifts.length < 7
          u.shift_status_message.include?("#{u.shifts.length} of 7 Shifts Selected.  You need to pick #{7 - u.shifts.length}").must_equal true
        else
          u.shift_status_message.include?("All required shifts selected for round 1. (7 of 7)").must_equal true
        end
        u.shifts << s
      end
    end
  end

  def test_show_selection_counts_for_round_two
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length > 12
        if u.shifts.length < 12
          u.shift_status_message.include?("#{u.shifts.length} of 12 Shifts Selected.  You need to pick #{12 - u.shifts.length}").must_equal true
        else
          u.shift_status_message.include?("All required shifts selected for round 2. (12 of 12)").must_equal true
        end
      end
    end
  end

  def test_show_selection_counts_for_round_three
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length >= 17
        if u.shifts.length < 17
          u.shift_status_message.include?("#{u.shifts.length} of 17 Shifts Selected.  You need to pick #{17 - u.shifts.length}").must_equal true
        end
      end

      u.shift_status_message.include?("All required shifts selected for round 3. (17 of 17)").must_equal true
    end
  end

  def test_show_selection_counts_for_round_four
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length >= 20
        if u.shifts.length < 20
          u.shift_status_message.include?("#{u.shifts.length} of 20 Shifts Selected.  You need to pick #{20 - u.shifts.length}").must_equal true
        else
          u.shift_status_message.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
        end
      end
      u.shift_status_message.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
    end
  end

  def test_show_proper_message_after_round_four_with_holiday
    holiday_shift = Shift.last
    holiday_shift.shift_date = HOLIDAYS[0]
    holiday_shift.save

    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 5)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    [@group1_user, @group2_user, @group3_user].each do |u|
      u.shifts << holiday_shift

      shifts.each do |s|
        u.shifts << s
        break if u.shifts.length >= 20

        msgs = u.shift_status_message

        u.shift_status_message.include?("#{u.shifts.length} of 20 Shifts Selected.  You need to pick #{20 - u.shifts.length}").must_equal true
        msgs.count.must_equal 3
      end
      msgs = u.shift_status_message
      msgs.include?("All required shifts selected.").must_equal true
      msgs.include?("You are currently in <strong>round 5</strong>.").must_equal false
      msgs.count.must_equal 3
    end
  end

  def test_show_proper_message_after_round_four_without_holiday
    config = SysConfig.first
    config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 5)
    config.save
    shifts = Shift.where("shift_type_id = #{@p1.id}")
    [@group1_user, @group2_user, @group3_user].each do |u|
      shifts.each do |s|
        # Don't allow a holiday shift
        next if HOLIDAYS.include? s.shift_date

        u.shifts << s
        break if u.shifts.length >= 20
        msgs = u.shift_status_message
        u.shift_status_message.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
        u.shift_status_message.include?("#{u.shifts.length} of 20 Shifts Selected.  You need to pick #{20 - u.shifts.length}").must_equal true
        msgs.count.must_equal 3
      end

      msgs = u.shift_status_message
      msgs.include?("All required shifts selected.").must_equal false
      msgs.include?("You are currently in <strong>round 5</strong>.").must_equal false
      msgs.include?("NOTE:  You still need a <strong>Holiday Shift</strong>").must_equal true
      msgs.count.must_equal 2
    end
  end
end