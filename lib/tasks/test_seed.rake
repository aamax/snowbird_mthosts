namespace :db do
  namespace :test do
    task :load => :environment do
      puts "Clearing all data: riders, host_haulers, shfits, shift_logs, shift_types"
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE riders RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE host_haulers RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shifts RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shift_logs RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shift_types RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE ongoing_trainings RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE training_dates RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE users RESTART IDENTITY;")

      puts "loading seed data for tests..."
      @sys_config = SysConfig.create(season_year: Date.today.year, group_1_year: 2005, group_2_year: 2009, group_3_year: 2012,
                       season_start_date: Date.new(Date.today.year,9,1), bingo_start_date: Date.today())

      puts User.all.count

      @rookie_user = FactoryBot.create(:user, name: 'rookie', start_year: Date.today.year, active_user: true, confirmed: true)
      @rookie2 = FactoryBot.create(:user, name: 'rookie2', start_year: Date.today.year, active_user: true, confirmed: true)
      @rookie3 = FactoryBot.create(:user, name: 'rookie3', start_year: Date.today.year, active_user: true, confirmed: true)

      puts User.all.count

      @group1_user = FactoryBot.create(:user, name: 'g1', start_year: 2005, active_user: true, confirmed: true)
      @group2_user = FactoryBot.create(:user, name: 'g2', start_year: 2009, active_user: true, confirmed: true)
      @group3_user = FactoryBot.create(:user, name: 'g3', start_year: 2012, active_user: true, confirmed: true)
      @team_leader = FactoryBot.create(:user, name: 'teamlead', start_year: 2005 , active_user: true, confirmed: true)
      @team_leader.add_role :team_leader

      # @surveyor = FactoryBot.create(:user, name: 'surveyor', start_year: 2005 , active_user: true, confirmed: true)
      # @surveyor.add_role :surveyor

      @trainer = FactoryBot.create(:user, name: 'trainer', start_year: 2005 , active_user: true, confirmed: true)
      @trainer.add_role :trainer

      @driver = FactoryBot.create(:user, name: 'driver', start_year: 2005 , active_user: true, confirmed: true)
      @driver.add_role :driver

      puts User.all.count

      User.all.each do |u|
        puts u.name
      end

      @tl = FactoryBot.create(:shift_type, short_name: 'TL')
      @a1 = FactoryBot.create(:shift_type, short_name: 'A1')

      # @oc = FactoryBot.create(:shift_type, short_name: 'OC')

      # @sv = FactoryBot.create(:shift_type, short_name: 'SV')
      # @sh = FactoryBot.create(:shift_type, short_name: 'SH')

      # Meetings
      @m1 = FactoryBot.create(:shift_type, short_name: 'M1')
      @m2 = FactoryBot.create(:shift_type, short_name: 'M2')
      # @m3 = FactoryBot.create(:shift_type, short_name: 'M3')
      @m4 = FactoryBot.create(:shift_type, short_name: 'M4')

      # rookie trainer shift
      @tr = FactoryBot.create(:shift_type, short_name: 'TR')

      # rookie trainee shifts
      @t1 = FactoryBot.create(:shift_type, short_name: 'T1')
      # @t2 = FactoryBot.create(:shift_type, short_name: 'T2')
      # @t3 = FactoryBot.create(:shift_type, short_name: 'T3')
      # @t4 = FactoryBot.create(:shift_type, short_name: 'T4')

      # ogomt trainer shifts
      # ogomt trainee shifts

      # regular shifts - weekend
      @p1end = FactoryBot.create(:shift_type, short_name: 'P1weekend')
      @p2end = FactoryBot.create(:shift_type, short_name: 'P2weekend')
      @p3end = FactoryBot.create(:shift_type, short_name: 'P3weekend')
      @p4end = FactoryBot.create(:shift_type, short_name: 'P4weekend')

      @g1end = FactoryBot.create(:shift_type, short_name: 'G1weekend')
      @g2end = FactoryBot.create(:shift_type, short_name: 'G2weekend')
      @g3end = FactoryBot.create(:shift_type, short_name: 'G3weekend')
      @g4end = FactoryBot.create(:shift_type, short_name: 'G4weekend')

      @c1end = FactoryBot.create(:shift_type, short_name: 'C1weekend')
      @c2end = FactoryBot.create(:shift_type, short_name: 'C2weekend')

      @h1end = FactoryBot.create(:shift_type, short_name: 'H1weekend')
      @h2end = FactoryBot.create(:shift_type, short_name: 'H2weekend')
      @h3end = FactoryBot.create(:shift_type, short_name: 'H3weekend')
      @h4end = FactoryBot.create(:shift_type, short_name: 'H4weekend')

      # regular shifts - weekday
      @p1day = FactoryBot.create(:shift_type, short_name: 'P1weekday')
      @p2day = FactoryBot.create(:shift_type, short_name: 'P2weekday')
      @p3day = FactoryBot.create(:shift_type, short_name: 'P3weekday')
      @p4day = FactoryBot.create(:shift_type, short_name: 'P4weekday')

      @g1day = FactoryBot.create(:shift_type, short_name: 'G1weekday')
      @g2day = FactoryBot.create(:shift_type, short_name: 'G2weekday')
      @g3day = FactoryBot.create(:shift_type, short_name: 'G3weekday')

      @h1day = FactoryBot.create(:shift_type, short_name: 'H1weekday')
      @h2day = FactoryBot.create(:shift_type, short_name: 'H2weekday')

      # @st = FactoryBot.create(:shift_type, short_name: 'ST')


      # TODO populate rookie training shifts
      # TODO populate OGOMT shifts

      @start_date = (Date.today()  + 60.days)
      curr_date = @start_date - 1.day
      (0..24).each do |d|
        curr_date += 1.day

        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p1end.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p2end.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p3end.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @p4end.id)

        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g1end.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g2end.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g3end.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @g4end.id)

        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @c1end.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @c2end.id)

        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @tl.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @a1.id)
      end

      # set up static rookie training dates
      curr_date = Shift::ROOKIE_TRAINING_WEEK1
      (0..37).each do |d|
        curr_date += 1.day
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @tr.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @t1.id)
        FactoryBot.create(:shift, shift_date: curr_date, shift_type_id: @t1.id)
      end

      puts "Shift Count (before meetings): #{Shift.count}"
      populate_test_meetings

      puts "Shift Count (All): #{Shift.count}"
      puts "All Users: #{User.count}"
      puts "Rookies: #{User.rookies.count}"
    end

    def populate_test_meetings
      # get all meetings
      meetings = ShiftType.where("short_name like 'M%'")

      puts "iterate all users..."

      User.all.each do |u|
        next if u.supervisor? || (u.active_user == false)

        meetings.each do |m|
          next if (m.short_name == 'M1' || m.short_name == 'M3') && !u.rookie?

          s_date = Date.parse(MEETINGS[m.short_name])

          new_shift = Shift.create(:user_id=>u.id,
                                   :shift_type_id=>m.id,
                                   :shift_date=>s_date,
                                   :shift_status_id => 1,
                                   :day_of_week=>s_date.strftime("%a"))
        end
      end
      puts "Done adding meetings.  Shift Count: #{Shift.all.count}"
    end
  end
end