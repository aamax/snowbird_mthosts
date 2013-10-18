module HostUtility
  def self.get_current_round(bingo_start, dt, usr)
    return 0 if dt < bingo_start

    day_count = (dt - bingo_start).to_i
    round_num = (day_count / 7).to_i + 1
    group_num = (day_count % 7).to_i
    return round_num if (round_num >= 5) || (usr.group_3?)
    return round_num if usr.group_2? && (group_num >= 2)
    return round_num if (usr.group_1? || usr.rookie?) && (group_num >= 4)
    return (round_num - 1)
  end

  def self.date_for_round(user, num)
    num_weeks = num - 1
    dt = HostConfig.bingo_start_date + num_weeks.weeks 
    if user.rookie? || user.group_1?
      dt += 4.days
    elsif user.group_2?
      dt += 2.days
    end
    dt
  end

  def self.bingo_start_for_round(user, num)
    num_weeks = num - 1
    dt = Date.today - num_weeks.weeks
    if user.rookie? || user.group_1?
      dt -= 4.days
    elsif user.group_2?
      dt -= 2.days
    end
    dt
  end
end