require 'csv'

namespace :db do
  desc "load all 2021 data"
  task :load_2021_data => :environment do
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

      puts 'Loading shift types'
      Rake::Task['db:load_2021_shift_types'].invoke

      puts 'load 2021 rookies into system'
      Rake::Task['db:load_2021_rookies'].invoke

      puts 'set up configs for season'
      Rake::Task['db:setup_config_for_2021'].invoke

      puts 'make host updates for current season'
      Rake::Task['db:update_2021_host_data_for_season'].invoke

      puts 'Load all shifts'
      Rake::Task['db:load_2021_shifts'].invoke

      puts 'Load all Rookie Training and Trainer Shifts'
      Rake::Task['db:load_2021_rookie_training_shifts'].invoke

      puts 'Load Team Lead Shadow Shifts'
      Rake::Task['db:load_2021_team_lead_shadow_shifts'].invoke

      puts "Shift Count Before Meetings: #{Shift.count}\n\n\n"

      puts 'Load all Meeting Shifts For Users'
      Rake::Task['db:load_2021_meetings'].invoke

      puts 'initialize all user accounts for start of year'
      User.reset_all_accounts

      puts 'Update Roles For users: Team lead, driver, admin, trainer, ogomt_trainer'
      Rake::Task['db:update_2021_host_roles'].invoke

      puts 'set my password and confirm me'
      # set my password
      u = User.find_by(email: 'aamaxworks@gmail.com')
      u.password = ENV['AAMAX_PGPASS']
      u.confirmed = true
      u.save

      puts 'initialize host hauler data for 2021'
      Rake::Task['db:initialize_2021host_hauler'].invoke

      puts "\n\n\n\n"

      Rake::Task['db:show_system_stats'].invoke
    end

    puts "DONE WITH SEASON PREP... 2021"
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
  task :load_2021_shift_types => :environment do
    # load up file
    filename = "lib/data/shift_type_2021.csv"

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

  desc 'load 2021 rookies'
  task :load_2021_rookies => :environment do
    puts "loading 2021 rookie data..."

    create_2021_rookie_user('Steve Altman', 'stevealtman2016@gmail.com')
    create_2021_rookie_user('Katie Bertram', 'katbertram235@yahoo.com')
    create_2021_rookie_user('Jennifer Carey', 'jcarey1017@outlook.com')
    create_2021_rookie_user('Jerry Christensen', 'daneindenmark@me.com')
    create_2021_rookie_user('Wilma Corkery', 'corkerywil@aol.com')
    create_2021_rookie_user('Jeffrey Ginsburg', 'jginzy@gmail.com')
    create_2021_rookie_user('Suzanne Glow', 'glowsum@yahoo.com')
    create_2021_rookie_user('Kelli Harrington', 'kaharrington@me.com')
    create_2021_rookie_user('Philip Jung', 'jungpbj@gmail.com')
    create_2021_rookie_user('Geof Kieburtz', 'gkieburtz@gmail.com')
    create_2021_rookie_user('Evan Matheson', 'ejmatheson@msn.com')
    create_2021_rookie_user('Tiffany Owens', 'jtcbowens@msn.com')
    create_2021_rookie_user('Cort Pouch', 'chpouch@gmail.com')
    create_2021_rookie_user('Nuri Pujao', 'nuri.betof@gmail.com')
    create_2021_rookie_user('Scott Strahan', 'sstrahan78@msn.com')
    create_2021_rookie_user('Craig Sturm', 'sturm.craig@gmail.com')

    puts "DONE WITH ROOKIE LOAD... "
  end

  desc "populate sys config settings for 2021"
  task :setup_config_for_2021 => :environment do
    puts "purging existing sys config record from system..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sys_configs RESTART IDENTITY;")
    c = SysConfig.new
    c.season_year = 2021
    c.group_1_year = 2014
    c.group_2_year = 2016
    c.group_3_year = 2017
    c.season_start_date = Date.new(2021, 10, 29)
    c.bingo_start_date = Date.new(2021, 11, 8)
    c.shift_count = 250  # TODO adjust up after bingo is done...

    if !c.save
      puts "error saving config record #{c.errors.messages}"
    end
    puts "Done with setting up System Config."
  end

  desc 'load all meetings and add to users'
  task :load_2021_meetings => :environment do
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

  desc 'update host data for current season'
  task :update_2021_host_data_for_season => :environment do
    puts "-----------------------------------------------"
    puts 'Re-activate Craig Whetman'
    activate_host('craig_whetman@hotmail.com')

    puts "-----------------------------------------------"
    puts 'Redshirting Hosts.....'
    puts "Harmony Mitchel"
    de_activate_host('meharmonymitchell@gmail.com')

    puts "Jennifer Reynolds"
    de_activate_host('skihounds@gmail.com')

    puts "Carol Mahany"
    de_activate_host('rlbskier@gmail.com')

    puts "Annette Coleman"
    de_activate_host('nettecoleman@hotmail.com')

    puts "-----------------------------------------------"
    puts "Retiring Hosts......"
    puts "Garth Driggs"
    de_activate_host('garthdriggs@gmail.com')

    puts "Lee Bethers"
    de_activate_host('leebethersxx@gmail.com')

    puts "Kevin Cullen"
    de_activate_host('kevin@logocompany.net')

    puts "Richard Vollmer"
    de_activate_host('rmj_vollmer@msn.com')

    puts "Catherine McEnroe"
    de_activate_host('cathmaclaughs@me.com')

    puts "Azim Merali"
    de_activate_host('azimmerali@gmail.com')

    puts "Kay Tran"
    de_activate_host('ktranvt@comcast.net')

    puts "Jarret Hallas"
    de_activate_host('yinyangyikes@gmail.com')

    puts "Troy Bate"
    de_activate_host('troybate@gmail.com')

    puts "Shawn Lima"
    de_activate_host('shawnlima@msn.com')

    puts "Connie Bain"
    de_activate_host('conniebain@comcast.net')

    puts "John Whetsone"
    de_activate_host('johnw.utah@gmail.com')

    puts "Ethan Fode"
    de_activate_host('thefode@yahoo.com')
    puts "-----------------------------------------------"
  end

  desc 'initialize host hauler'
  task :initialize_2021host_hauler => :environment do
    jc = User.find_by(email: 'jecotterii@gmail.com')
    (Date.parse('2021-12-01')..Date.parse('2022-05-30')).each do |dt|
      if dt.wednesday? || dt.thursday? || dt.friday? || dt.saturday? || dt.sunday?
        HostHauler.add_hauler(dt, jc.id)
      else
        HostHauler.add_hauler(dt)
      end
    end
    puts 'Done adding initial host hauler dates and seats...'
  end

  desc "populate shifts"
  task :load_2021_shifts => :environment do
    # 12/1 - 12/17:  5 hosts per day
    ('2021-12-01'.to_date..'2021-12-17'.to_date).each do |dt|
      create_flex_host_day(dt, 5)
    end

    # 12/18 - 12/19 regular weekend
    ('2021-12-18'.to_date..'2021-12-19'.to_date).each do |dt|
      create_weekend_shift(dt)
    end

    # 12/20 - 12/21 regular weekday
    ('2021-12-20'.to_date..'2021-12-21'.to_date).each do |dt|
      create_weekday_shift(dt)
    end

    # 12/22 - 1/2 regular weekend
    ('2021-12-22'.to_date..'2022-01-02'.to_date).each do |dt|
      create_weekend_shift(dt)
    end

    # 1/3 - 4/17 regular shifts: weekday/weekend
    ('2022-01-03'.to_date..'2022-04-17'.to_date).each do |dt|
      if (dt.saturday? || dt.sunday?)
        create_weekend_shift(dt)
      else
        create_weekday_shift(dt)
      end
    end

    # 1/17 & 2/21:  regular weekend
    ('2022-01-17'.to_date..'2022-02-21'.to_date).each do |dt|
      create_weekend_shift(dt)
    end

    # 4/18 - 5/1:  4 hosts per day
    ('2022-04-18'.to_date..'2022-05-01'.to_date).each do |dt|
      create_flex_host_day(dt, 4)
    end

    # 5/2 - 5/30: 4 hosts per day just Sat/Sun
    ('2022-05-02'.to_date..'2022-05-29'.to_date).each do |dt|
      create_flex_host_day(dt, 4) if (dt.saturday? || dt.sunday?)
    end

    # Memorial Day
    create_flex_host_day('2022-05-30'.to_date, 4)
  end

  desc 'update host roles'
  task :update_2021_host_roles => :environment do
    # set drivers
    # Same Hosts that were drivers last year are drivers this year.
    update_user_role('akmarler@hotmail.com', :driver)
    update_user_role('dostar227@msn.com', :driver)
    update_user_role('snoman2490@msn.com', :driver)
    update_user_role('altabirdskiers@gmail.com', :driver)
    update_user_role('jecotterii@gmail.com', :driver)
    update_user_role('itinslc@hotmail.com', :driver)
    update_user_role('alohamaddy@yahoo.com', :driver)
    update_user_role('mikedufordconst@yahoo.com', :driver)

    # set rookie trainers
    # Rookie Trainers are Paul E, Eric Sawyer, Kris Hill, Sarah Reifsntder
    update_user_role('snowsawyer@hotmail.com', :trainer)
    update_user_role('krishill0@gmail.com', :trainer)
    update_user_role('altasnow@gmail.com', :trainer)
    update_user_role('sarah3884@yahoo.com', :trainer)

    # set ogomt trainers
    # OGOMT Trainers are Paul E, Eric Sawyer, Kris Hill, Sarah Reifsntder and Craig Whetman
    update_user_role('snowsawyer@hotmail.com', :ongoing_trainer)
    update_user_role('krishill0@gmail.com', :ongoing_trainer)
    update_user_role('altasnow@gmail.com', :ongoing_trainer)
    update_user_role('sarah3884@yahoo.com', :ongoing_trainer)
    update_user_role('craig_whetman@hotmail.com', :ongoing_trainer)

    # set admins me and john
    update_user_role('aamaxworks@gmail.com', :admin)
    update_user_role('jecotterii@gmail.com', :admin)

    # set team leaders
    # Team Leaders:
    update_user_role('buglady@me.com', :team_leader)
    update_user_role('alohamaddy@yahoo.com', :team_leader)
    update_user_role('mikedufordconst@yahoo.com', :team_leader)
    update_user_role('heidi@netdiverse.com', :team_leader)
    update_user_role('larry.walz@me.com', :team_leader)
    update_user_role('snoman2490@msn.com', :team_leader)
    update_user_role('giperez@earthlink.net', :team_leader)
    update_user_role('akmarler@hotmail.com', :team_leader)
    update_user_role('gmlj56@gmail.com', :team_leader)
    update_user_role('sarah3884@yahoo.com', :team_leader)
    update_user_role('herkyp@yahoo.com', :team_leader)
    update_user_role('markhooyer@gmail.com', :team_leader)
  end

  desc "populate rookie training and trainer shifts"
  task :load_2021_rookie_training_shifts => :environment do
    paul = User.find_by(email: 'altasnow@gmail.com')
    eric = User.find_by(email: 'snowsawyer@hotmail.com')
    kris = User.find_by(email: 'krishill0@gmail.com')
    sarah = User.find_by(email: 'sarah3884@yahoo.com')

    court = User.find_by(email: 'chpouch@gmail.com')
    craig = User.find_by(email: 'sturm.craig@gmail.com')
    jen = User.find_by(email: 'jcarey1017@outlook.com')
    jeff = User.find_by(email: 'jginzy@gmail.com')
    kelli = User.find_by(email: 'kaharrington@me.com')
    tiffany = User.find_by(email: 'jtcbowens@msn.com')
    philip = User.find_by(email: 'jungpbj@gmail.com')
    steve = User.find_by(email: 'stevealtman2016@gmail.com')
    geoff = User.find_by(email: 'gkieburtz@gmail.com')
    suzanne = User.find_by(email: 'glowsum@yahoo.com')
    wilma = User.find_by(email: 'corkerywil@aol.com')
    scott = User.find_by(email: 'sstrahan78@msn.com')
    katie = User.find_by(email: 'katbertram235@yahoo.com')
    evan = User.find_by(email: 'ejmatheson@msn.com')
    jerry = User.find_by(email: 'daneindenmark@me.com')
    nuri = User.find_by(email: 'nuri.betof@gmail.com')

    create_rookie_training_day('2021-12-20'.to_date, paul, [court, craig, jen])

    create_rookie_training_day('2021-12-21'.to_date, eric, [jeff, kelli, tiffany])

    create_rookie_training_day('2021-12-22'.to_date, sarah, [philip, steve])

    create_rookie_training_day('2021-12-23'.to_date, paul, [evan, jerry, geoff])

    create_rookie_training_day('2021-12-24'.to_date, paul, [katie, suzanne, wilma])

    create_rookie_training_day('2021-12-26'.to_date, kris, [scott])

    create_rookie_training_day('2021-12-26'.to_date, eric, [court, geoff])

    create_rookie_training_day('2021-12-28'.to_date, kris, [steve, jeff, tiffany])

    create_rookie_training_day('2021-12-29'.to_date, eric, [craig, jen, wilma])

    create_rookie_training_day('2021-12-30'.to_date, paul, [evan, jerry, suzanne])

    create_rookie_training_day('2021-12-31'.to_date, paul, [philip, katie])

    create_rookie_training_day('2022-01-01'.to_date, paul, [kelli, scott])

    create_rookie_training_day('2022-01-02'.to_date, kris, [katie, suzanne])

    create_rookie_training_day('2022-01-04'.to_date, eric, [craig, steve, tiffany])

    create_rookie_training_day('2022-01-05'.to_date, kris, [philip, jen, kelli])

    create_rookie_training_day('2022-01-06'.to_date, kris, [evan, jerry, jeff])

    create_rookie_training_day('2022-01-07'.to_date, kris, [court, geoff, wilma])

    create_rookie_training_day('2022-01-08'.to_date, paul, [scott])

    create_rookie_training_day('2022-01-09'.to_date, eric, [katie, geoff])

    create_rookie_training_day('2022-01-11'.to_date, sarah, [suzanne, wilma])

    create_rookie_training_day('2022-01-12'.to_date, sarah, [jen, kelli, tiffany])

    create_rookie_training_day('2022-01-13'.to_date, eric, [evan, jerry, steve])

    create_rookie_training_day('2022-01-14'.to_date, eric, [craig, court, philip])

    create_rookie_training_day('2022-01-15'.to_date, paul, [scott, jeff])
  end

  desc "populate team lead shadow shifts"
  task :load_2021_team_lead_shadow_shifts => :environment do
    puts "loading team lead and shadow shifts for training"

    larry = User.find_by(email: 'larry.walz@me.com')
    heidi = User.find_by(email: 'heidi@netdiverse.com')
    gigi = User.find_by(email: 'gmlj56@gmail.com')
    mark = User.find_by(email: 'markhooyer@gmail.com')

    shift = Shift.find_by(short_name: 'TL', shift_date: '2021-12-18')
    shift.user_id = heidi.id
    shift.save!

    create_shift_with_host('TShadow', '2021-12-18', gigi.id)
    create_shift_with_host('TShadow', '2021-12-18', mark.id)

    shift = Shift.find_by(short_name: 'TL', shift_date: '2021-12-19')
    shift.user_id = larry.id
    shift.save!

    create_shift_with_host('TShadow', '2021-12-19', mark.id)

    shift = Shift.find_by(short_name: 'TL', shift_date: '2021-12-21')
    shift.user_id = larry.id
    shift.save!

    create_shift_with_host('TShadow', '2021-12-21', gigi.id)
  end

  def update_user_role(email, role)
    u = User.find_by(email: email)
    u.add_role role
  end

  def de_activate_host(email)
    u = User.find_by(email: email)
    u.active_user = false
    u.save
  end

  def activate_host(email)
    u = User.find_by(email: email)
    u.active_user = true
    u.save
  end

  def create_2021_rookie_user(name_value, email_value)
    puts "creating rookie: #{name_value} #{email_value}"
    usr = User.find_by(email: email_value)
    if !usr.nil?
      puts "Possible Error! =========>  User Already Exists: #{email_value} - #{usr.name}"
      return
    end

    usr = User.new(name: name_value, email: email_value, password: DEFAULT_PASSWORD)
    usr.active_user = true
    usr.start_year = 2021
    usr.snowbird_start_year = 2021
    if !usr.valid?
      puts "\nERRROR in data:  #{usr.errors.messages}\n#{usr.inspect}\n-----\n#{hash}\n\n"
    end
    usr.save
  end

  def create_shift(shift_short_name, dt)
    shift_type_id = ShiftType.find_by(short_name: shift_short_name).id
    st = {
      shift_type_id: shift_type_id,
      shift_status_id: 1,
      shift_date: dt
    }
    if !Shift.create(st)
      puts "ERROR\n    short_name: #{shift_short_name}\n------------\n\n"
      raise 'error loading shifts'
    end
  end

  def create_shift_with_host(shift_short_name, dt, host_id)
    shift_type_id = ShiftType.find_by(short_name: shift_short_name).id
    st = {
      shift_type_id: shift_type_id,
      shift_status_id: 1,
      shift_date: dt,
      user_id: host_id
    }
    if !Shift.create(st)
      puts "ERROR\n    short_name: #{shift_short_name}\n------------\n\n"
      raise 'error loading shifts'
    end
  end

  def create_flex_host_day(dt, num_shifts)
    # clear day of shifts
    Shift.where(shift_date: dt).delete_all

    for counter in 1..num_shifts
      create_shift('A1', dt)
    end
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

    create_shift('TL', dt)
  end

  def create_rookie_training_day(dt, trainer, rookies)
    create_shift_with_host('TR', dt, trainer.id)

    rookies.each do |rookie|
      create_shift_with_host('T1', dt, rookie.id)
    end
  end
end

