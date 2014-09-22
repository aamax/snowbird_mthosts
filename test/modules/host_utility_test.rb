# require_relative "../test_helper"
#
# class HostUtilityTest < ActiveSupport::TestCase
#
#   # def test_round_number_rookie_1
#   #   @sys_config = SysConfig.first
#   #   puts "start year: #{@sys_config.season_year}"
#   #
#   #   user = FactoryGirl.create(:user, :email => 'f1.user@example.com', :start_year => @sys_config.season_year, :active_user => true)
#   #   bingo_start = Date.today
#   #   curr_date = Date.today
#   #   val = HostUtility.get_current_round(bingo_start, curr_date, user)
#   #   assert_equal(val, 1, 'round 1 test fails')
#   # end
#
#   def test_round_four_starts_on_same_date_for_all_users
#     HostUtility.bingo_start_for_round(@newer_user, 4).must_equal  HostUtility.bingo_start_for_round(@senior_user, 4)
#
#
#   end
# end