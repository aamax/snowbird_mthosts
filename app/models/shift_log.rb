# == Schema Information
#
# Table name: shift_logs
#
#  id           :integer          not null, primary key
#  change_date  :datetime
#  user_id      :integer
#  shift_id     :integer
#  action_taken :string
#  note         :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class ShiftLog < ActiveRecord::Base
end
