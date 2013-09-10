module ShiftsHelper
  def getShiftTotal(adate)
    Shift.where("shift_date = ?", adate).count
  end

  def getSelectedShifts(adate)
    Shift.where("shift_date = ? and user_id is null", adate).count
  end
end
