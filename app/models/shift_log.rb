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
  belongs_to :user
  belongs_to :shift

  def shift_info
    if self.shift.nil?
      "#{self.shift_id}:DELETED SHIFT - see notes"
    else
      "#{self.shift_id}:#{self.shift.shift_date.strftime("%Y-%m-%d")}:#{self.shift.short_name}"
    end
  end
end
