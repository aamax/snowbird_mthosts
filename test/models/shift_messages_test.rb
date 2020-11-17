require "test_helper"

class ShiftMessagesTest < ActiveSupport::TestCase
  before do
    @sys_config = SysConfig.first
    @newer_user = User.find_by_name('g3')
    @middle_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g1')
    @team_leader = User.find_by_name('teamlead')

    @a1 = ShiftType.find_by_short_name('A1')
    @tl = ShiftType.find_by_short_name('TL')
    @oc = ShiftType.find_by_short_name('OC')

    Timecop.return
    Timecop.freeze(HostUtility.date_for_round(@senior_user, 4)) # shifts after bingo done

    (1..50).each do |n|
      FactoryBot.create(:shift, shift_type_id: @tl.id, shift_date: Date.today + n.days)
      FactoryBot.create(:shift, shift_type_id: @a1.id, shift_date: Date.today + n.days)
      FactoryBot.create(:shift, shift_type_id: @oc.id, shift_date: Date.today + n.days)
    end
  end

    describe 'pre-bingo' do
      before do
        Timecop.return
        Timecop.freeze(HostUtility.date_for_round(@senior_user, 0))

        @tl_msgs = @team_leader.shift_status_message
        @sr_msgs = @senior_user.shift_status_message
        @mi_msgs = @middle_user.shift_status_message
        @nw_msgs = @newer_user.shift_status_message
      end

      it 'should show correct message for users' do
        @tl_msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
        @sr_msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
        @mi_msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true
        @nw_msgs.include?("You are currently in <strong>round 0</strong>.").must_equal true

        @tl_msgs.include?("Today is: #{Date.today.strftime('%Y-%m-%d')}").must_equal true
        @sr_msgs.include?("Today is: #{Date.today.strftime('%Y-%m-%d')}").must_equal true
        @mi_msgs.include?("Today is: #{Date.today.strftime('%Y-%m-%d')}").must_equal true
        @nw_msgs.include?("Today is: #{Date.today.strftime('%Y-%m-%d')}").must_equal true

        @tl_msgs.include?("Bingo Start: #{HostUtility.date_for_round(@senior_user, 1)}").must_equal true
        @sr_msgs.include?("Bingo Start: #{HostUtility.date_for_round(@senior_user, 1)}").must_equal true
        @mi_msgs.include?("Bingo Start: #{HostUtility.date_for_round(@senior_user, 1)}").must_equal(true, @mi_msgs)
        @nw_msgs.include?("Bingo Start: #{HostUtility.date_for_round(@senior_user, 1)}").must_equal true

        @tl_msgs.include?("0 team leader shifts selected").must_equal true

        @sr_msgs.include?("No Selections Until #{HostUtility.date_for_round(@senior_user, 1)}.").must_equal(true, @sr_msgs)
        @mi_msgs.include?("No Selections Until #{HostUtility.date_for_round(@middle_user, 1)}.").must_equal(true, @mi_msgs)
        @nw_msgs.include?("No Selections Until #{HostUtility.date_for_round(@newer_user, 1)}.").must_equal(true, @nw_msgs)
      end
  end

  describe 'round 1' do
    describe 'senior users' do
      before do
        Timecop.return
        Timecop.freeze(HostUtility.date_for_round(@senior_user, 1))
      end

      it 'should show correct message for users' do
        @sr_msgs = @senior_user.shift_status_message
        @sr_msgs.include?("You are currently in <strong>round 1</strong>.").must_equal true

        @sr_msgs.include?("Today is: #{Date.today.strftime('%Y-%m-%d')}").must_equal true

        @sr_msgs.include?("Bingo Start: #{HostUtility.date_for_round(@senior_user, 1)}").must_equal true
        @sr_msgs.include?("2 of 7 Shifts Selected.  You need to pick 5").must_equal(true, @sr_msgs)

        # iterate 1..5... iterate and pick if can select... check message
        for i in 1..4 do
          Shift.all.each do |s|
            if s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)) == true
              @senior_user.shifts << s
              msgs = @senior_user.shift_status_message
              msgs.include?("#{2 + i} of 7 Shifts Selected.  You need to pick #{5 - i}").must_equal(true,
                  "#{msgs} vs [#{2 + i} of 7 Shifts Selected.  You need to pick #{5 - i}]")
              break
            end
          end
        end
        Shift.all.each do |s|
          if s.can_select(@senior_user, HostUtility.can_select_params_for(@senior_user)) == true
            @senior_user.shifts << s
            msgs = @senior_user.shift_status_message
            msgs.include?("All required shifts selected for round 1. (7 of 7)").must_equal(true, msgs)
            break
          end
        end
      end
    end

    it 'should show correct message for middle users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@middle_user, 1))
      validate_user_messages(@middle_user, 1)
    end

    it 'should show correct message for newer users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@newer_user, 1))
      validate_user_messages(@newer_user, 1)
    end
  end


  describe 'round 2' do
    it 'should show correct message for senior users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@senior_user, 2))
      validate_user_messages(@senior_user, 2)
    end

    it 'should show correct message for middle users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@middle_user, 2))
      validate_user_messages(@middle_user, 2)
    end

    it 'should show correct message for newer users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@newer_user, 2))
      validate_user_messages(@newer_user, 2)
    end
  end

  describe 'round 3' do
    it 'should show correct message for senior users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@senior_user, 3))
      validate_user_messages(@senior_user, 3)
    end

    it 'should show correct message for middle users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@middle_user, 3))
      validate_user_messages(@middle_user, 3)
    end

    it 'should show correct message for newer users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@newer_user, 3))
      validate_user_messages(@newer_user, 3)
    end
  end

  describe 'round 4' do
    it 'should show correct message for senior users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@senior_user, 4))
      validate_user_messages(@senior_user, 4)
    end

    it 'should show correct message for middle users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@middle_user, 4))
      validate_user_messages(@middle_user, 4)
    end

    it 'should show correct message for newer users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@newer_user, 4))
      validate_user_messages(@newer_user, 4)
    end
  end

  describe 'post-bingo' do
    it 'should show correct message for senior users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@senior_user, 5))
      select_count_shifts(@senior_user, 20)
      msgs = @senior_user.shift_status_message
      msgs.include?("You have at least 19 shifts selected").must_equal(true, msgs)
    end

    it 'should show correct message for middle users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@middle_user, 5))
      select_count_shifts(@middle_user, 20)
      msgs = @middle_user.shift_status_message
      msgs.include?("You have at least 19 shifts selected").must_equal(true, msgs)
    end

    it 'should show correct message for newer users' do
      Timecop.return
      Timecop.freeze(HostUtility.date_for_round(@newer_user, 5))
      select_count_shifts(@newer_user, 20)
      msgs = @newer_user.shift_status_message
      msgs.include?("You have at least 19 shifts selected").must_equal(true, msgs)
    end
  end


  def validate_user_messages(usr, round)
    shift_target = round * 5 + 2
    shift_target = SHIFT_TARGET if shift_target > SHIFT_TARGET
    msgs = usr.shift_status_message
    msgs.include?("You are currently in <strong>round #{round}</strong>.").must_equal(true, msgs)

    msgs.include?("Today is: #{Date.today.strftime('%Y-%m-%d')}").must_equal(true, msgs)

    msgs.include?("Bingo Start: #{HostUtility.date_for_round(@senior_user, 1)}")
        .must_equal(true, "#{msgs}")
    msgs.include?("#{usr.shifts.count} of #{shift_target} Shifts Selected.  You need to pick #{shift_target - usr.shifts.count}")
        .must_equal(true, "[#{usr.shifts.count} of #{shift_target} Shifts Selected.  You need to pick #{shift_target - usr.shifts.count}] #{msgs}")

    for i in 1..((round * 5) - 2) do
      break if i == SHIFT_TARGET - 2
      Shift.all.each do |s|
        if s.can_select(usr, HostUtility.can_select_params_for(usr)) == true
          usr.shifts << s
          msgs2 = usr.shift_status_message

          msgs2.include?("#{2 + i} of #{shift_target} Shifts Selected.  You need to pick #{shift_target - 2 - i}")
                .must_equal(true,
                            "#{msgs2} vs [#{2 + i} of #{shift_target} Shifts Selected.  You need to pick #{shift_target - 2 - i}]")
          break
        end
      end
    end
    Shift.all.each do |s|
      if s.can_select(usr, HostUtility.can_select_params_for(usr)) == true
        usr.shifts << s
        msgs2 = usr.shift_status_message
        if usr.shifts.count < SHIFT_TARGET
          msgs2.include?("#{usr.shifts.count} of #{shift_target} Shifts Selected.  You need to pick #{shift_target - usr.shifts.count}")
            .must_equal(true, "[#{msgs2}] vs. [#{usr.shifts.count} of #{shift_target} Shifts Selected.  You need to pick #{shift_target - usr.shifts.count}]")
        else
          msgs2.include?("You have at least #{SHIFT_TARGET} shifts selected").must_equal true
        end
        break
      end

    end
  end

  def select_count_shifts(usr, count)
    Shift.all.each do |s|
      return if usr.shifts.count >= count

      if s.can_select(usr, HostUtility.can_select_params_for(usr)) == true
        usr.shifts << s
      end
    end
  end



  # def setup
  #   HostConfig.initialize_values
  #
  #   @sys_config = SysConfig.first
  #   @group1_user = User.find_by_name('g1')
  #   @group2_user = User.find_by_name('g2')
  #   @group3_user = User.find_by_name('g3')
  #   @tl_user = User.find_by_name('TL')
  #   @a1 = ShiftType.find_by_short_name('A1')
  #   @oc = ShiftType.find_by_short_name('OC')
  #   @tl = ShiftType.find_by_short_name('teamlead')
  # end

  # def test_shift_picking_before_round_one
  #   config = SysConfig.first
  #   config.bingo_start_date = Date.today + 10.days
  #   config.save
  #
  #   @group1_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group1_user, 1)}.").must_equal true
  #   @group2_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group2_user, 1)}.").must_equal true
  #   @group3_user.shift_status_message.include?("No Selections Until #{HostUtility.date_for_round(@group3_user, 1)}.").must_equal true
  # end
  #
  # def test_after_bingo_messages
  #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
  #   @sys_config.save
  #
  #   Shift.all.each do |s|
  #     if s.can_select(@group1_user, HostUtility.can_select_params_for(@group1_user))
  #       @group1_user.shifts << s
  #     end
  #   end
  #
  #   assert_operator(20, :<, @group1_user.shifts.count)
  #   msgs = @group1_user.shift_status_message
  #   msgs.include?("You have at least 20 shifts selected").must_equal true
  # end
  #
  # def test_round_one_status_messages
  #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group2_user, 1)
  #   @sys_config.save
  #   Shift.all.each do |s|
  #     if s.can_select(@group2_user, HostUtility.can_select_params_for(@group2_user))
  #       @group2_user.shifts << s
  #     end
  #   end
  #   @group2_user.shifts.count.must_equal 7
  #   msgs = @group2_user.shift_status_message
  #   msgs.include?("You are currently in <strong>round 1</strong>.").must_equal true
  #   msgs.include?("All required shifts selected for round 1. (7 of 7)").must_equal true
  # end
  #
  # def test_round_two_status_messages
  #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 2)
  #   @sys_config.save
  #   Shift.all.each do |s|
  #     if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
  #       @group3_user.shifts << s
  #     end
  #   end
  #   @group3_user.shifts.count.must_equal 12
  #   msgs = @group3_user.shift_status_message
  #   msgs.include?("You are currently in <strong>round 2</strong>.").must_equal true
  #   msgs.include?("All required shifts selected for round 2. (12 of 12)").must_equal true
  # end
  #
  # def test_round_three_status_messages
  #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 3)
  #   @sys_config.save
  #   Shift.all.each do |s|
  #     if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
  #       @group3_user.shifts << s
  #     end
  #   end
  #   @group3_user.shifts.count.must_equal 17
  #   msgs = @group3_user.shift_status_message
  #   msgs.include?("You are currently in <strong>round 3</strong>.").must_equal true
  #   msgs.include?("All required shifts selected for round 3. (17 of 17)").must_equal true
  # end
  #
  # def test_round_four_status_messages
  #   @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@group3_user, 4)
  #   @sys_config.save
  #   Shift.all.each do |s|
  #     if s.can_select(@group3_user, HostUtility.can_select_params_for(@group3_user))
  #       @group3_user.shifts << s
  #     end
  #   end
  #   @group3_user.shifts.count.must_equal 20
  #   msgs = @group3_user.shift_status_message
  #   msgs.include?("You are currently in <strong>round 4</strong>.").must_equal true
  #   msgs.include?("All required shifts selected for round 4. (20 of 20)").must_equal true
  # end
  #
  # def test_report_shift_count_after_selection_rounds
  #   config = SysConfig.first
  #   config.bingo_start_date = HostUtility.bingo_start_for_round(@group1_user, 6)
  #   config.save
  #
  #   @group1_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
  #   @group2_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
  #   @group3_user.shift_status_message.include?("2 of 20 Shifts Selected.  You need to pick 18").must_equal true
  # end
end