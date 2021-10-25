namespace :data do
  task :load_meetings => :environment do
    puts "clearing all meeting shifts..."

    meetings = ShiftType.where("short_name = 'M1' OR short_name = 'M2' OR short_name = 'M3' OR short_name = 'M4'").map {|st| st.id}.join(',')

    if meetings.empty?
      ShiftType.create(short_name: 'M1', description: 'test meeting1')
      ShiftType.create(short_name: 'M2', description: 'test meeting2')
      ShiftType.create(short_name: 'M3', description: 'test meeting3')
      ShiftType.create(short_name: 'M4', description: 'test meeting4')
      meetings = ShiftType.where("short_name = 'M1' OR short_name = 'M2' OR short_name = 'M3' OR short_name = 'M4'").map {|st| st.id}.join(',')
    end

    Shift.delete_all("shift_type_id in (#{meetings})")

    first_date = SysConfig.first.season_start_date
    shift_types = {}
    ShiftType.all.each {|st| shift_types[st.short_name] = st.id }

    puts "iterate all users..."
    User.all.each do |u|
      next if u.supervisor? || (u.active_user == false)

      puts "adding meetings to: #{u.name}"
      MEETINGS.each do |m|
        next if ((m[:type] == "M1") || (m[:type] == "M3")) && !u.rookie?

        s_date = Date.parse(m[:when])
        st = shift_types[m[:type]]

        new_shift = Shift.create(:user_id=>u.id,
                                 :shift_type_id=>st,
                                 :shift_date=>s_date,
                                 :shift_status_id => 1,
                                 :day_of_week=>s_date.strftime("%a"))
      end
    end
    puts "done..."
  end
end