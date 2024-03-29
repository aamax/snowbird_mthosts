#  RAILS_ENV=production bundle exec rake db:load_2022_data

require 'csv'

namespace :db do
  desc "load all 2022 data"
  task :load_2022_data => :environment do
    ActiveRecord::Base.transaction do
      # clear all data
      puts "Clearing all data: riders, host_haulers, shfits, shift_logs, shift_types"
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE riders RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE host_haulers RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shifts RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shift_logs RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shift_types RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE ongoing_trainings RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE training_dates RESTART IDENTITY;")

      # add supervisor (Brandon)
      usr = User.find_by(email: SUPERVISOR_EMAIL)
      if !usr.nil?
        puts "=========>  Supervisor User Already Exists: #{usr.email} - #{usr.name}"
        usr.start_year = 2021 # fake it so he isn't a rookie
      else
        usr = User.new(name: 'Brandon Fessler', email: SUPERVISOR_EMAIL, password: DEFAULT_PASSWORD)
        usr.active_user = true
        usr.start_year = 2022
        usr.snowbird_start_year = 2022
        if !usr.valid?
          puts "\nERRROR in data:  #{usr.errors.messages}\n#{usr.inspect}\n-----\n#{hash}\n\n"
        end
      end
      usr.save
      update_user_role(SUPERVISOR_EMAIL, :admin)
      update_user_role(SUPERVISOR_EMAIL, :supervisor)

      puts 'Loading shift types'
      Rake::Task['db:load_2022_shift_types'].invoke

      puts 'load 2021 rookies into system'
      Rake::Task['db:load_2022_rookies'].invoke

      puts 'set up configs for season'
      Rake::Task['db:setup_config_for_2022'].invoke

      puts 'Load all shifts'
      Rake::Task['db:load_2022_shifts'].invoke

      puts 'Load all Rookie Training and Trainer Shifts'
      Rake::Task['db:load_2022_rookie_training_shifts'].invoke

#       puts 'Load Team Lead Shadow Shifts'
#       Rake::Task['db:load_2021_team_lead_shadow_shifts'].invoke
#
#       puts "Shift Count Before Meetings: #{Shift.count}\n\n\n"

      puts 'Load all Meeting Shifts For Users'
      Rake::Task['db:load_2022_meetings'].invoke

      puts 'initialize all user accounts for start of year'
      User.reset_all_accounts(false)

      puts 'Update Roles For users: Team lead, driver, admin, trainer, ogomt_trainer'
      Rake::Task['db:update_2022_host_roles'].invoke

#       puts 'set my password and confirm me'
#       # set my password
#       u = User.find_by(email: 'aamaxworks@gmail.com')
#       u.password = ENV['AAMAX_PGPASS']
#       u.confirmed = true
#       u.save
#
#       puts 'initialize host hauler data for 2021'
#       Rake::Task['db:initialize_2021host_hauler'].invoke
#
      puts "\n\n\n\n"

      Rake::Task['db:show_system_stats'].invoke
    end

    puts "DONE WITH SEASON PREP... 2022"
  end

  desc "load early season 2022 shifts"
  task :add_reporting_role => :environment do
    u = User.find_by(email: 'aamaxworks@gmail.com')
    u.add_role :reporting unless u.nil?
  end

  desc "load early season 2022 shifts"
  task :load_2022_early_shifts => :environment do
    ('2022-11-18'.to_date..'2022-11-29'.to_date).each do |dt|
      create_disabled_flex_host_day(dt, 4)
      add_team_leader_shift(dt)
    end

  end

  desc "show system stats for review"
  task :show_system_stats => :environment do
    puts "Active User Count #{User.active_users.count}"
    puts "Shift Types: #{ShiftType.count}"
    puts "Shift Count: #{Shift.count}"

    puts "Seniors: #{User.group1.count}"
    puts "Juniors: #{User.group2.count}"
    puts "Freshmen: #{User.group3.count}"
    puts "Rookies: #{User.rookies.count}"
  end

  desc "populate shift types"
  task :load_2022_shift_types => :environment do
    # load up file
    filename = "lib/data/shift_type_2022.csv"

    if File.exists?(filename)
      puts "loading shift type data..."
      CSV.foreach(filename, :headers => true) do |row|
        hash = row.to_hash

        next if (row[0].to_s == '#') || hash['short_name'].nil?

        st = ShiftType.new(hash)
        if !st.save
          puts "failed: #{hash} - #{st.errors.messages}"
        end
      end
      puts "done loading shift type data.  Type Count: #{ShiftType.all.count}"
    else
      puts "shift type loader file not found"
    end
  end

  desc 'load 2022 rookies'
  task :load_2022_rookies => :environment do
    puts "loading 2022 rookie data..."

    create_2022_rookie_user('Sue Bias', 'bias.sooze@gmail.com')
    create_2022_rookie_user('Tiffany Bloomquist', 'tiffbloomquist@gmail.com')
    create_2022_rookie_user('Dustin Jackman', 'dustinjackman@gmail.com')
    create_2022_rookie_user('Kathy McBane', 'ski.mcbane@gmail.com')
    create_2022_rookie_user('Christina Patten', 'chrissypatten@gmail.com')
    create_2022_rookie_user('Lucy Littlewood', 'lucylittlewood@hotmail.co.uk')
    create_2022_rookie_user('George Walker', 'geowalkerjr@msn.com')
    create_2022_rookie_user('Patrice Zhoa', 'patrice.zhao@gmail.com')
    create_2022_rookie_user('Peter Vander', 'petervander11@gmail.com')
    create_2022_rookie_user('Christy Steele', 'steele.christie@gmail.com')

    puts "DONE WITH ROOKIE LOAD... "
  end

  desc "populate sys config settings for 2022"
  task :setup_config_for_2022 => :environment do
    puts "purging existing sys config record from system..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sys_configs RESTART IDENTITY;")
    c = SysConfig.new
    c.season_year = 2022
    c.group_1_year = 2014
    c.group_2_year = 2019
    c.group_3_year = 2021
    c.season_start_date = Date.new(2022, 10, 29)
    c.bingo_start_date = Date.new(2022, 11, 7)
    c.shift_count = 250  # TODO adjust up after bingo is done...

    if !c.save
      puts "error saving config record #{c.errors.messages}"
    end
    puts "Done with setting up System Config."
  end

  desc 'load all meetings and add to users'
  task :load_2022_meetings => :environment do
    # delete all existing meeting shifts
    puts "delete all existing meetings"
    Shift.where(short_name: 'M1').delete_all
    Shift.where(short_name: 'M2').delete_all
    Shift.where(short_name: 'M3').delete_all
    Shift.where(short_name: 'M4').delete_all

    # get all meetings
    meetings = ShiftType.where("short_name like 'M%'")

    puts "iterate all users..."
    User.all.each do |u|
      next if u.supervisor? || (u.active_user == false)

      meetings.each do |m|
        next if ((m.short_name == 'M1') || (m.short_name == 'M3')) && !u.rookie?

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


  desc 'initialize host hauler'
  task :initialize_2022host_hauler => :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE riders RESTART IDENTITY;")
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE host_haulers RESTART IDENTITY;")

    (Date.parse('2022-12-01')..Date.parse('2023-05-30')).each do |dt|
      HostHauler.add_hauler(dt)
    end
    puts 'Done adding initial host hauler dates and seats...'
  end

  desc "populate shifts"
  task :load_2022_shifts => :environment do
    # # 11/30 - 12/16:  5 hosts per day
    ('2022-11-30'.to_date..'2022-12-16'.to_date).each do |dt|
      create_flex_host_day(dt, 4)
      add_team_leader_shift(dt)
    end

    # end of season flex host days
    date_set = []
    ('2023-04-17'.to_date..'2023-04-30'.to_date).each do |dt|
      date_set << dt
    end
    ('2023-05-05'.to_date..'2023-05-07'.to_date).each do |dt|
      date_set << dt
    end
    ('2023-05-12'.to_date..'2023-05-14'.to_date).each do |dt|
      date_set << dt
    end
    ('2023-05-19'.to_date..'2023-05-21'.to_date).each do |dt|
      date_set << dt
    end
    ('2023-05-26'.to_date..'2023-05-29'.to_date).each do |dt|
      date_set << dt
    end
    date_set.each do |dt|
      create_flex_host_day(dt, 2)
      add_team_leader_shift(dt)
    end

    weekday_dates = []
    holiday_dates = []

    # holiday dates
    holiday_dates << '2022-12-17'.to_date
    holiday_dates << '2022-12-18'.to_date
    ('2022-12-21'.to_date..'2023-01-02'.to_date).each do |dt|
      holiday_dates << dt
    end
    holiday_dates << '2023-01-07'.to_date
    holiday_dates << '2023-01-08'.to_date
    holiday_dates << '2023-01-14'.to_date
    holiday_dates << '2023-01-15'.to_date
    holiday_dates << '2023-01-16'.to_date
    holiday_dates << '2023-01-21'.to_date
    holiday_dates << '2023-01-22'.to_date
    holiday_dates << '2023-01-28'.to_date
    holiday_dates << '2023-01-29'.to_date
    holiday_dates << '2023-02-04'.to_date
    holiday_dates << '2023-02-05'.to_date
    holiday_dates << '2023-02-11'.to_date
    holiday_dates << '2023-02-12'.to_date
    holiday_dates << '2023-02-18'.to_date
    holiday_dates << '2023-02-19'.to_date
    holiday_dates << '2023-02-20'.to_date
    holiday_dates << '2023-02-25'.to_date
    holiday_dates << '2023-02-26'.to_date
    holiday_dates << '2023-03-04'.to_date
    holiday_dates << '2023-03-05'.to_date
    holiday_dates << '2023-03-11'.to_date
    holiday_dates << '2023-03-12'.to_date
    holiday_dates << '2023-03-18'.to_date
    holiday_dates << '2023-03-19'.to_date
    holiday_dates << '2023-03-25'.to_date
    holiday_dates << '2023-03-26'.to_date
    holiday_dates << '2023-04-01'.to_date
    holiday_dates << '2023-04-02'.to_date
    holiday_dates << '2023-04-08'.to_date
    holiday_dates << '2023-04-09'.to_date
    holiday_dates << '2023-04-15'.to_date
    holiday_dates << '2023-04-16'.to_date

    # weekday_dates
    weekday_dates << '2022-12-19'.to_date
    weekday_dates << '2022-12-20'.to_date
    weekday_dates << '2023-01-03'.to_date
    weekday_dates << '2023-01-04'.to_date
    weekday_dates << '2023-01-05'.to_date
    weekday_dates << '2023-01-06'.to_date
    weekday_dates << '2023-01-09'.to_date
    weekday_dates << '2023-01-10'.to_date
    weekday_dates << '2023-01-11'.to_date
    weekday_dates << '2023-01-12'.to_date
    weekday_dates << '2023-01-13'.to_date
    weekday_dates << '2023-01-17'.to_date
    weekday_dates << '2023-01-18'.to_date
    weekday_dates << '2023-01-19'.to_date
    weekday_dates << '2023-01-20'.to_date
    weekday_dates << '2023-01-23'.to_date
    weekday_dates << '2023-01-24'.to_date
    weekday_dates << '2023-01-25'.to_date
    weekday_dates << '2023-01-26'.to_date
    weekday_dates << '2023-01-27'.to_date
    weekday_dates << '2023-01-30'.to_date
    weekday_dates << '2023-01-31'.to_date
    weekday_dates << '2023-02-01'.to_date
    weekday_dates << '2023-02-02'.to_date
    weekday_dates << '2023-02-03'.to_date
    weekday_dates << '2023-02-06'.to_date
    weekday_dates << '2023-02-07'.to_date
    weekday_dates << '2023-02-08'.to_date
    weekday_dates << '2023-02-09'.to_date
    weekday_dates << '2023-02-10'.to_date

    weekday_dates << '2023-02-13'.to_date
    weekday_dates << '2023-02-14'.to_date
    weekday_dates << '2023-02-15'.to_date
    weekday_dates << '2023-02-16'.to_date
    weekday_dates << '2023-02-17'.to_date


    weekday_dates << '2023-02-21'.to_date
    weekday_dates << '2023-02-22'.to_date
    weekday_dates << '2023-02-23'.to_date
    weekday_dates << '2023-02-24'.to_date
    weekday_dates << '2023-02-27'.to_date
    weekday_dates << '2023-02-28'.to_date
    weekday_dates << '2023-03-01'.to_date
    weekday_dates << '2023-03-02'.to_date
    weekday_dates << '2023-03-03'.to_date
    weekday_dates << '2023-03-06'.to_date
    weekday_dates << '2023-03-07'.to_date
    weekday_dates << '2023-03-08'.to_date
    weekday_dates << '2023-03-09'.to_date
    weekday_dates << '2023-03-10'.to_date
    weekday_dates << '2023-03-13'.to_date
    weekday_dates << '2023-03-14'.to_date
    weekday_dates << '2023-03-15'.to_date
    weekday_dates << '2023-03-16'.to_date
    weekday_dates << '2023-03-17'.to_date
    weekday_dates << '2023-03-20'.to_date
    weekday_dates << '2023-03-21'.to_date
    weekday_dates << '2023-03-22'.to_date
    weekday_dates << '2023-03-23'.to_date
    weekday_dates << '2023-03-24'.to_date
    weekday_dates << '2023-03-27'.to_date
    weekday_dates << '2023-03-28'.to_date
    weekday_dates << '2023-03-29'.to_date
    weekday_dates << '2023-03-30'.to_date
    weekday_dates << '2023-03-31'.to_date
    weekday_dates << '2023-04-03'.to_date
    weekday_dates << '2023-04-04'.to_date
    weekday_dates << '2023-04-05'.to_date
    weekday_dates << '2023-04-06'.to_date
    weekday_dates << '2023-04-07'.to_date
    weekday_dates << '2023-04-10'.to_date
    weekday_dates << '2023-04-11'.to_date
    weekday_dates << '2023-04-12'.to_date
    weekday_dates << '2023-04-13'.to_date
    weekday_dates << '2023-04-14'.to_date

    holiday_dates.each do |dt|
      create_weekend_shift(dt)
    end

    weekday_dates.each do |dt|
      create_weekday_shift(dt)
    end
    create_shift('TS', '2022-12-17'.to_date)
    create_shift('TS', '2022-12-18'.to_date)
  end

  desc 'update host roles'
  task :update_2022_host_roles => :environment do
    # set drivers
    update_user_role('akmarler@hotmail.com', :driver)
    update_user_role('dostar227@msn.com', :driver)
    update_user_role('snoman2490@msn.com', :driver)
    update_user_role('alohamaddy@yahoo.com', :driver)
    update_user_role('mikedufordconst@yahoo.com', :driver)
    update_user_role('jcal57@yahoo.com', :driver)
    update_user_role('altabirdskiers@gmail.com', :driver)
    update_user_role('itinslc@hotmail.com', :driver)
    update_user_role('sarah3884@yahoo.com', :driver)

    # set rookie trainers
    # Rookie Trainers are Paul E, Eric Sawyer, Kris Hill, Sarah Reifsntder
    update_user_role('krishill0@gmail.com', :trainer)
    update_user_role('sarah3884@yahoo.com', :trainer)


    # set admins me and supervisor
    update_user_role('aamaxworks@gmail.com', :admin)
    update_user_role(SUPERVISOR_EMAIL, :admin)

    # set team leaders
    # Team Leaders:
    update_user_role('alohamaddy@yahoo.com', :team_leader)
    update_user_role('mikedufordconst@yahoo.com', :team_leader)
    update_user_role('buglady@me.com', :team_leader)
    update_user_role('markhooyer@gmail.com', :team_leader)
    update_user_role('gmlj56@gmail.com', :team_leader)
    update_user_role('jonelast@hotmail.com', :team_leader)
    update_user_role('snoman2490@msn.com', :team_leader)
    update_user_role('akmarler@hotmail.com', :team_leader)
    update_user_role('heidi@netdiverse.com', :team_leader)
    update_user_role('dostar227@msn.com', :team_leader)
    update_user_role('sarah3884@yahoo.com', :team_leader)
    update_user_role('herkyp@yahoo.com', :team_leader)
    update_user_role('larry.walz@me.com', :team_leader)
    update_user_role('giperez@earthlink.net', :team_leader)

    # de-activate non-returning hosts
    de_activate_host('dldeisley@gmail.com')
    de_activate_host('giperez@earthlink.net')
    de_activate_host('rlbskier@gmail.com')
    de_activate_host('snowsawyer@hotmail.com')
    de_activate_host('brneiman@comcast.net')
    de_activate_host('nettecoleman@hotmail.com')
  end

  desc "populate rookie training and trainer shifts"
  task :load_2022_rookie_training_shifts => :environment do
    kris = User.find_by(email: 'krishill0@gmail.com')
    sarah = User.find_by(email: 'sarah3884@yahoo.com')

    sarah_shifts = [
      '2022-12-06','2022-12-09','2022-12-10',
      '2022-12-17','2022-12-18',
      '2022-12-20','2022-12-22','2022-12-23','2022-12-24','2023-01-09',
      '2023-01-13'
    ]

    kris_shifts = [
      '2022-12-11','2022-12-13','2022-12-14','2022-12-16','2023-01-10',
      '2023-01-14','2023-01-15'
    ]

    sarah_shifts.each do |s|
      create_rookie_training_day(s.to_date, sarah)
    end
    kris_shifts.each do |s|
      create_rookie_training_day(s.to_date, kris)
      # if s == '2023-01-15'
      #   # disable for makeup day
      #
      # end
    end
  end

  def is_disabled(dt, shift_short_name)
    ((shift_short_name == 'TR') || (shift_short_name == 'T1')) && ((dt == '2023-01-15'.to_date) || (dt == '2022-12-18'.to_date))
  end

  def create_shift_with_host(shift_short_name, dt, host_id)
    shift_type_id = ShiftType.find_by(short_name: shift_short_name).id
    st = {
      shift_type_id: shift_type_id,
      shift_status_id: 1,
      shift_date: dt,
      user_id: host_id,
      disabled: is_disabled(dt, shift_short_name)
    }

    if !Shift.create(st)
      puts "ERROR\n    short_name: #{shift_short_name}\n------------\n\n"
      raise 'error loading shifts'
    end
  end

  def create_rookie_training_day(dt, trainer)
    # create trainer shift
    create_shift_with_host('TR', dt, trainer.id)

    # create 3 rookie trainee shifts
    (1..3).each do |d|
      create_shift('T1', dt)
    end
  end

#   desc "populate team lead shadow shifts"
#   task :load_2021_team_lead_shadow_shifts => :environment do
#     puts "loading team lead and shadow shifts for training"
#
#     larry = User.find_by(email: 'larry.walz@me.com')
#     heidi = User.find_by(email: 'heidi@netdiverse.com')
#     gigi = User.find_by(email: 'gmlj56@gmail.com')
#     mark = User.find_by(email: 'markhooyer@gmail.com')
#
#     shift = Shift.find_by(short_name: 'TL', shift_date: '2021-12-18')
#     shift.user_id = heidi.id
#     shift.save!
#
#     create_shift_with_host('TShadow', '2021-12-18', gigi.id)
#     create_shift_with_host('TShadow', '2021-12-18', mark.id)
#
#     shift = Shift.find_by(short_name: 'TL', shift_date: '2021-12-19')
#     shift.user_id = larry.id
#     shift.save!
#
#     create_shift_with_host('TShadow', '2021-12-19', mark.id)
#
#     shift = Shift.find_by(short_name: 'TL', shift_date: '2021-12-21')
#     shift.user_id = larry.id
#     shift.save!
#
#     create_shift_with_host('TShadow', '2021-12-21', gigi.id)
#   end
#

  def update_user_role(email, role)
    u = User.find_by(email: email)
    u.add_role role unless u.nil?

    puts "User Not Found Error: #{email}" if u.nil?
  end

  def de_activate_host(email)
    u = User.find_by(email: email)
    u.active_user = false
    u.save
  end

#   def activate_host(email)
#     u = User.find_by(email: email)
#     u.active_user = true
#     u.save
#   end
#

  def create_2022_rookie_user(name_value, email_value)
    puts "creating rookie: #{name_value} #{email_value}"
    usr = User.find_by(email: email_value)
    if !usr.nil?
      puts "Possible Error! =========>  User Already Exists: #{email_value} - #{usr.name}"
      return
    end

    usr = User.new(name: name_value, email: email_value, password: DEFAULT_PASSWORD)
    usr.active_user = true
    usr.start_year = 2022
    usr.snowbird_start_year = 2022
    if !usr.valid?
      puts "\nERRROR in data:  #{usr.errors.messages}\n#{usr.inspect}\n-----\n#{hash}\n\n"
    end
    usr.save
  end

  def create_weekend_shift(dt)
    # clear day of shifts
    Shift.where(shift_date: dt).delete_all

    create_shift('P1weekend', dt)
    create_shift('P2weekend', dt)
    create_shift('P3weekend', dt)
    create_shift('P4weekend', dt)

    create_shift('H1weekend', dt)
    create_shift('H2weekend', dt)
    create_shift('H3weekend', dt)
    create_shift('H4weekend', dt)

    create_shift('G1weekend', dt)
    create_shift('G2weekend', dt)
    create_shift('G3weekend', dt)
    create_shift('G4weekend', dt)

    create_shift('C1weekend', dt)
    create_shift('C2weekend', dt)
    # create_shift('Survey', dt)

    create_shift('TL', dt)
  end

  def create_weekday_shift(dt)
    # clear day of shifts
    Shift.where(shift_date: dt).delete_all

    create_shift('P1weekday', dt)
    create_shift('P3weekday', dt)
    create_shift('P4weekday', dt)

    create_shift('G1weekday', dt)
    create_shift('G2weekday', dt)
    create_shift('G3weekday', dt)

    create_shift('H1weekday', dt)
    create_shift('H2weekday', dt)
    # create_shift('Survey', dt)

    create_shift('TL', dt)
  end

  def create_flex_host_day(dt, num_shifts)
    # clear day of shifts
    Shift.where(shift_date: dt).delete_all

    for counter in 1..num_shifts
      create_shift('A1', dt)
    end
  end

  def create_disabled_flex_host_day(dt, num_shifts)
    # clear day of shifts
    Shift.where(shift_date: dt).delete_all

    for counter in 1..num_shifts
      create_disabled_shift('A1', dt)
    end
  end

  def create_disabled_shift(shift_short_name, dt)
    shift_type_id = ShiftType.find_by(short_name: shift_short_name).id
    st = {
      shift_type_id: shift_type_id,
      shift_status_id: 1,
      shift_date: dt,
      disabled: true
    }

    if !Shift.create(st)
      puts "ERROR\n    short_name: #{shift_short_name}\n------------\n\n"
      raise 'error loading shifts'
    end
  end

  def create_shift(shift_short_name, dt)
    shift_type_id = ShiftType.find_by(short_name: shift_short_name).id
    st = {
      shift_type_id: shift_type_id,
      shift_status_id: 1,
      shift_date: dt,
      disabled: is_disabled(dt, shift_short_name)
    }

    # if (shift_short_name == 'T1') && ((dt == '2023-01-15'.to_date) || (dt == '2022-12-18'.to_date))
    #   st[:disabled] = true
    # end

    if !Shift.create(st)
      puts "ERROR\n    short_name: #{shift_short_name}\n------------\n\n"
      raise 'error loading shifts'
    end
  end

  def add_team_leader_shift(dt)
    create_shift('TL', dt)
  end


end

