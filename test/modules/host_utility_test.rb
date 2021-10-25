require_relative "../test_helper"

class HostUtilityTest < ActiveSupport::TestCase
  def setup_vars
    @sys_config = SysConfig.first

    @rookie_user = User.find_by_name('rookie')
    @newer_user = User.find_by_name('g3')
    @middle_user = User.find_by_name('g2')
    @senior_user = User.find_by_name('g1')
    @team_leader = User.find_by_name('teamlead')
    @trainer = User.find_by_name('trainer')
  end

  def test_round_1
    setup_vars
    # senior on bingo start day and following 2
    HostUtility.get_current_round(Date.today(), Date.today(), @senior_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 1.day, @senior_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 2.day, @senior_user).must_equal 1

    # junior on bingo start + 1 and following 2
    HostUtility.get_current_round(Date.today(), Date.today()+ 1.day, @middle_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 2.day, @middle_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 3.day, @middle_user).must_equal 1

    # freshman and rookie on bingo start + 2 and following 2
    HostUtility.get_current_round(Date.today(), Date.today()+ 2.day, @newer_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 3.day, @newer_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 4.day, @newer_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today()+ 2.day, @rookie_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 3.day, @rookie_user).must_equal 1
    HostUtility.get_current_round(Date.today(), Date.today() + 4.day, @rookie_user).must_equal 1
  end

  def test_round_2
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() + 3, @senior_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 4.day, @senior_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 5.day, @senior_user).must_equal 2

    # junior
    HostUtility.get_current_round(Date.today(), Date.today()+ 4.day, @middle_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 5.day, @middle_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 6.day, @middle_user).must_equal 2

    # freshman and rookie
    HostUtility.get_current_round(Date.today(), Date.today()+ 5.day, @newer_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 6.day, @newer_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 7.day, @newer_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today()+ 5.day, @rookie_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 6.day, @rookie_user).must_equal 2
    HostUtility.get_current_round(Date.today(), Date.today() + 7.day, @rookie_user).must_equal 2
  end

  def test_round_3
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() + 6, @senior_user).must_equal 3
    HostUtility.get_current_round(Date.today(), Date.today() + 7.day, @senior_user).must_equal 3
    HostUtility.get_current_round(Date.today(), Date.today() + 8.day, @senior_user).must_equal 3

    # junior
    HostUtility.get_current_round(Date.today(), Date.today()+ 7.day, @middle_user).must_equal 3
    HostUtility.get_current_round(Date.today(), Date.today() + 8.day, @middle_user).must_equal 3

    # freshman and rookie
    HostUtility.get_current_round(Date.today(), Date.today()+ 8.day, @newer_user).must_equal 3
    HostUtility.get_current_round(Date.today(), Date.today()+ 8.day, @rookie_user).must_equal 3
  end

  def test_round_4
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() + 9, @senior_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 10.day, @senior_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 11.day, @senior_user).must_equal 4

    # junior



    # binding.pry

    HostUtility.get_current_round(Date.today(), Date.today()+ 9.day, @middle_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 10.day, @middle_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 11.day, @middle_user).must_equal 4

    # freshman and rookie
    HostUtility.get_current_round(Date.today(), Date.today()+ 9.day, @newer_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 10.day, @newer_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 11.day, @newer_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today()+ 9.day, @rookie_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 10.day, @rookie_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 11.day, @rookie_user).must_equal 4
  end

  def test_pre_bingo
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() - 1, @senior_user).must_equal 0

    # junior
    HostUtility.get_current_round(Date.today(), Date.today() - 1.day, @middle_user).must_equal 0

    # freshman and rookie
    HostUtility.get_current_round(Date.today(), Date.today() - 1.day, @newer_user).must_equal 0
  end

  def test_post_bingo
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() + 12, @senior_user).must_equal 5

    # junior
    HostUtility.get_current_round(Date.today(), Date.today() + 12.day, @middle_user).must_equal 5

    # freshman and rookie
    HostUtility.get_current_round(Date.today(), Date.today() + 12.day, @newer_user).must_equal 5
  end
end