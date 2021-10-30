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

    @bingo_start = HostConfig.bingo_start_date
  end

  def test_get_current_round_1
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

  def test_get_current_round_2
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

  def test_get_current_round_3
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

  def test_get_current_round_4
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() + 9, @senior_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 10.day, @senior_user).must_equal 4
    HostUtility.get_current_round(Date.today(), Date.today() + 11.day, @senior_user).must_equal 4

    # junior
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

  def test_get_current_pre_bingo
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() - 1, @senior_user).must_equal 0

    # junior
    HostUtility.get_current_round(Date.today(), Date.today() - 1.day, @middle_user).must_equal 0

    # freshman and rookie
    HostUtility.get_current_round(Date.today(), Date.today() - 1.day, @newer_user).must_equal 0
  end

  def test_get_current_post_bingo
    setup_vars

    # senior
    HostUtility.get_current_round(Date.today(), Date.today() + 12, @senior_user).must_equal 5

    # junior
    HostUtility.get_current_round(Date.today(), Date.today() + 12.day, @middle_user).must_equal 5

    # freshman and rookie
    HostUtility.get_current_round(Date.today(), Date.today() + 12.day, @newer_user).must_equal 5
  end

  def test_get_date_for_round_1
    setup_vars
    HostUtility.date_for_round(@senior_user, 1).must_equal @bingo_start
    HostUtility.date_for_round(@middle_user, 1).must_equal @bingo_start + 1.day
    HostUtility.date_for_round(@newer_user, 1).must_equal @bingo_start + 2.day
    HostUtility.date_for_round(@rookie_user, 1).must_equal @bingo_start + 2.day
  end

  def test_get_date_for_round_2
    setup_vars
    HostUtility.date_for_round(@senior_user, 2).must_equal @bingo_start + 3.days
    HostUtility.date_for_round(@middle_user, 2).must_equal @bingo_start + 4.days
    HostUtility.date_for_round(@newer_user, 2).must_equal @bingo_start + 5.days
    HostUtility.date_for_round(@rookie_user, 2).must_equal @bingo_start + 5.days
  end

  def test_get_date_for_round_3
    setup_vars
    HostUtility.date_for_round(@senior_user, 3).must_equal @bingo_start + 6.days
    HostUtility.date_for_round(@middle_user, 3).must_equal @bingo_start + 7.days
    HostUtility.date_for_round(@newer_user, 3).must_equal @bingo_start + 8.days
    HostUtility.date_for_round(@rookie_user, 3).must_equal @bingo_start + 8.days
  end

  def test_get_date_for_round_4
    setup_vars
    HostUtility.date_for_round(@senior_user, 4).must_equal @bingo_start + 9.days
    HostUtility.date_for_round(@middle_user, 4).must_equal @bingo_start + 9.days
    HostUtility.date_for_round(@newer_user, 4).must_equal @bingo_start + 9.days
    HostUtility.date_for_round(@rookie_user, 4).must_equal @bingo_start + 9.days
  end

  def test_get_date_for_round_5
    setup_vars
    HostUtility.date_for_round(@senior_user, 5).must_equal @bingo_start + 12.days
    HostUtility.date_for_round(@middle_user, 5).must_equal @bingo_start + 12.days
    HostUtility.date_for_round(@newer_user, 5).must_equal @bingo_start + 12.days
    HostUtility.date_for_round(@rookie_user, 5).must_equal @bingo_start + 12.days
  end

  def test_bingo_start_for_round_1
    setup_vars
    HostUtility.bingo_start_for_round(@senior_user, 1).must_equal Date.today
    HostUtility.bingo_start_for_round(@middle_user, 1).must_equal Date.today - 1.day
    HostUtility.bingo_start_for_round(@newer_user, 1).must_equal Date.today - 2.day
    HostUtility.bingo_start_for_round(@rookie_user, 1).must_equal Date.today - 2.day
  end

  def test_bingo_start_for_round_2
    setup_vars
    HostUtility.bingo_start_for_round(@senior_user, 2).must_equal Date.today - 3.day
    HostUtility.bingo_start_for_round(@middle_user, 2).must_equal Date.today - 4.day
    HostUtility.bingo_start_for_round(@newer_user, 2).must_equal Date.today - 5.day
    HostUtility.bingo_start_for_round(@rookie_user, 2).must_equal Date.today - 5.day
  end

  def test_bingo_start_for_round_3
    setup_vars
    HostUtility.bingo_start_for_round(@senior_user, 3).must_equal Date.today - 6.day
    HostUtility.bingo_start_for_round(@middle_user, 3).must_equal Date.today - 7.day
    HostUtility.bingo_start_for_round(@newer_user, 3).must_equal Date.today - 8.day
    HostUtility.bingo_start_for_round(@rookie_user, 3).must_equal Date.today - 8.day
  end

  def test_bingo_start_for_round_4
    setup_vars
    HostUtility.bingo_start_for_round(@senior_user, 4).must_equal Date.today - 9.day
    HostUtility.bingo_start_for_round(@middle_user, 4).must_equal Date.today - 9.day
    HostUtility.bingo_start_for_round(@newer_user, 4).must_equal Date.today - 9.day
    HostUtility.bingo_start_for_round(@rookie_user, 4).must_equal Date.today - 9.day
  end

  def test_bingo_start_for_round_5
    setup_vars
    HostUtility.bingo_start_for_round(@senior_user, 5).must_equal Date.today - 12.day
    HostUtility.bingo_start_for_round(@middle_user, 5).must_equal Date.today - 12.day
    HostUtility.bingo_start_for_round(@newer_user, 5).must_equal Date.today - 12.day
    HostUtility.bingo_start_for_round(@rookie_user, 5).must_equal Date.today - 12.day
  end

end