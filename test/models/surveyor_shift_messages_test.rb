require "test_helper"

class SurveyorMessageTest < ActiveSupport::TestCase
  def setup
    HostConfig.initialize_values

    @sys_config = SysConfig.first
    @surveyor = User.find_by_name('g1')
    @surveyor.add_role :surveyor
    @svtype = ShiftType.find_by(short_name: 'SV')

    (1..50).each do |n|
      FactoryGirl.create(:shift, shift_type_id: @svtype.id, shift_date: Date.today + n.days)
    end
  end

  describe "surveyor messages" do
    def test_show_surveyor_shift_count_pre_bingo
      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@surveyor, 0)
      @sys_config.save

      Shift.where(short_name: 'SV').each do |s|
        if s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          @surveyor.shifts << s
        end
      end

      Shift.all.each do |s|
        if s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          @surveyor.shifts << s
        end
      end
      (@surveyor.shifts.count == 11).must_equal true
      (@surveyor.survey_shift_count == 9).must_equal true
      msgs = @surveyor.shift_status_message
      msgs.include?("9 of 9 surveyor shifts selected").must_equal true
    end

    def test_show_surveyor_shift_count_in_round_4
      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@surveyor, 4)
      @sys_config.save

      Shift.where(short_name: 'SV').each do |s|
        if s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          @surveyor.shifts << s
        end
      end

      Shift.all.each do |s|
        if s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          @surveyor.shifts << s
        end
      end
      (@surveyor.shifts.count == 20).must_equal true
      msgs = @surveyor.shift_status_message
      msgs.include?("9 of 9 surveyor shifts selected").must_equal true
    end

    def test_show_surveyor_shift_count_post_bingo
      @sys_config.bingo_start_date = HostUtility.bingo_start_for_round(@surveyor, 6)
      @sys_config.save

      Shift.where(short_name: 'SV').each do |s|
        if s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          @surveyor.shifts << s
        end
      end

      Shift.all.each do |s|
        if s.can_select(@surveyor, HostUtility.can_select_params_for(@surveyor))
          @surveyor.shifts << s
        end
      end
      (@surveyor.shifts.count >= 20).must_equal true
      (@surveyor.survey_shift_count >= 9).must_equal true
      msgs = @surveyor.shift_status_message
      msgs.include?("50 of 9 surveyor shifts selected").must_equal true
    end
  end
end
