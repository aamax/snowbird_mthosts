module HostUtility
  def self.display_user_and_shift(user, shift)
    puts "----- User and shift info --------"
    puts "Bingo Start: #{SysConfig.first.bingo_start_date}"
    puts "Seniority: #{user.seniority}   seniority_group: #{user.seniority_group}"
    puts "Current Round: #{HostUtility.get_current_round(SysConfig.first.bingo_start_date, Date.today, user)}"
    (1..5).each do |num|
      puts "    date for round: #{num}  -  #{HostUtility.date_for_round(user, num)}"
    end


    puts "user: rookie: #{user.rookie?}  g1: #{user.group_1?} g2: #{user.group_2?}  g3: #{user.group_3?}"
    puts "start year #{user.start_year}"

    puts "shadow cnt: #{user.shadow_count} last shadow: #{user.last_shadow} "
    puts "rnd1 cnt: #{user.round_one_type_count}  rnd1 first: #{user.first_round_one_end_date}  rnd1 end: #{user.round_one_end_date}"
    puts "first non round 1: #{user.first_non_round_one_end_date} is working: #{user.is_working?(shift.shift_date)}"
    puts ""

    puts "current shift: #{shift.shift_date}  short_name: #{shift.short_name} can select: #{shift.can_select(user)}"
    puts ""

    user.shifts.each do |s|
      puts "dt: #{s.shift_date}  shortname: #{s.short_name}"
    end
    puts "=================================="
  end

  def self.get_current_round(bingo_start, dt, usr)
    return 0 if dt < bingo_start

    day_count = (dt - bingo_start).to_i
    round_num = (day_count / 7).to_i + 1
    group_num = (day_count % 7).to_i
    return round_num if (round_num >= 5) || (usr.group_1?)
    return round_num if usr.group_2? && (group_num >= 2)
    return round_num if (usr.group_3? || usr.rookie?) && (group_num >= 4)
    return (round_num - 1)
  end

  def self.date_for_round(user, num)
    num_weeks = num - 1
    dt = HostConfig.bingo_start_date + num_weeks.weeks 
    if user.rookie? || user.group_3?
      dt += 4.days
    elsif user.group_2?
      dt += 2.days
    end
    dt
  end

  def self.bingo_start_for_round(user, num)
    num_weeks = num - 1
    dt = Date.today - num_weeks.weeks
    if user.rookie? || user.group_3?
      dt -= 4.days
    elsif user.group_2?
      dt -= 2.days
    end
    dt
  end
end