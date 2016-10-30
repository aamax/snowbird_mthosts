# == Schema Information
#
# Table name: shifts
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  shift_type_id   :integer          not null
#  shift_status_id :integer          default(1), not null
#  shift_date      :date
#  day_of_week     :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  short_name      :string
#

module ShiftsHelper
  def getShiftTotal(adate)
    Shift.where("shift_date = ?", adate).count
  end

  def getSelectedShifts(adate)
    Shift.where("shift_date = ? and user_id is null", adate).count
  end
end
