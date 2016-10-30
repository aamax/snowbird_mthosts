# == Schema Information
#
# Table name: shift_types
#
#  id          :integer          not null, primary key
#  short_name  :string(255)      not null
#  description :string(255)      not null
#  start_time  :string(255)
#  end_time    :string(255)
#  tasks       :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require "test_helper"

class ShiftTypesControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
end
