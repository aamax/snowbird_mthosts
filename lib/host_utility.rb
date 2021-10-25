module HostUtility

  def self.can_select_params_for(user)
    all_shifts = user.shifts.to_a
    working_shifts = user.shifts.to_a.delete_if {|s| s.meeting? || s.trainer? || s.survey?}
    bingo_start = HostConfig.bingo_start_date
    round = HostUtility.get_current_round(bingo_start, Date.today, user)
    shift_count = working_shifts.count
    {all_shifts: all_shifts, working_shifts: working_shifts, bingo_start: bingo_start,
                     round: round, shift_count: shift_count}
  end

  def self.display_user_and_shift(user, shift)
    bingo_start = HostConfig.bingo_start_date
    round = HostUtility.get_current_round(bingo_start, Date.today, user)

    puts "----- User and shift info --------"
    puts "Bingo Start: #{bingo_start}"
    puts "Seniority: #{user.seniority}   seniority_group: #{user.seniority_group}"

    puts "Current Round: #{round}"
    puts "Total shifts selected: #{user.shifts.count}"
    (1..5).each do |num|
      puts "    date for round: #{num}  -  #{HostUtility.date_for_round(user, num)}"
    end


    puts "user: rookie: #{user.rookie?}  g1: #{user.group_1?} g2: #{user.group_2?}  g3: #{user.group_3?}"
    puts "start year #{user.start_year}"

    puts "training shifts: #{user.training_shifts_list}"
    puts "rnd1 cnt: #{user.round_one_type_count}  rnd1 first: #{user.first_round_one_end_date}  rnd1 end: #{user.round_one_end_date}"
    puts "first non round 1: #{user.first_non_round_one_end_date} is already working: #{user.is_working?(shift.shift_date)}"
    puts ""

    all_shifts = user.shifts.to_a
    working_shifts = user.shifts.to_a.delete_if {|s| s.meeting? || s.trainer? || s.survey?}
    shift_count = working_shifts.count
    select_params = {all_shifts: all_shifts, working_shifts: working_shifts, bingo_start: bingo_start,
                     round: round, shift_count: shift_count}

    puts "current shift: #{shift.shift_date}  short_name: #{shift.full_short_name} can select: #{shift.can_select(user, select_params)}"
    puts ""
    puts "is trainee: #{user.is_trainee_on_date(shift.shift_date)}"
    puts ""

    puts "shifts for user:"
    user.shifts.each do |s|
      puts "dt: #{s.shift_date}  shortname: #{s.short_name}"
    end
    puts ""

    puts "shifts on date: #{shift.shift_date}"
    shifts = Shift.where("shift_date = '#{shift.shift_date}'")
    shifts.each do |s|
      puts "short_name: #{s.full_short_name}  host: #{s.user_id.nil? ? "nil" : s.user.name }"
    end

    puts "=================================="
  end

  def self.get_current_round(bingo_start, dt, usr)
    return 0 if dt < bingo_start

    case usr.seniority_group
      when 1 # senior
        day_count = (dt - bingo_start).to_i
        round_num = (day_count / 3).to_i + 1
      when 2 # junior
        day_count = (dt - bingo_start).to_i - 1
        round_num = (day_count / 3).to_i + 1
        group_num = (day_count % 3).to_i

        if (round_num == 3 || round_num == 4) && group_num == 2
          round_num += 1
        end
      when 3,4 # freshman or rookie
        day_count = (dt - bingo_start).to_i - 2
        round_num = (day_count / 3).to_i + 1

        group_num = (day_count % 3).to_i

        if (round_num == 3 || round_num == 4) && group_num > 0
          round_num += 1
        end
      else
    end

    return round_num
  end

  def self.date_for_round(user, round_num)
    num_days = (round_num - 1) * 2
    dt = HostConfig.bingo_start_date + num_days.days
    if user.rookie?
      dt += 1.days
    elsif user.group_2? || user.group_3?
      dt += 1.day
    end
    dt
  end

  def self.bingo_start_for_round(user, num)
    num_rounds = num - 1
    dt = Date.today - (num_rounds * 2).days

    if user.rookie? || user.group_3?
      dt -= 1.days
    elsif user.group_2?
      dt -= 1.day
    end
    dt
  end
end
