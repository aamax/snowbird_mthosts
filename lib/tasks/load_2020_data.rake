require 'csv'

namespace :db do
  desc "load all 2020 data"
  task :load_all_2020_data => :environment do
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
      Rake::Task['db:load_2020_shift_types'].invoke

      puts 'set up configs for season'
      Rake::Task['db:setup_config_for_2020'].invoke

      puts 'make host updates for current season'
      Rake::Task['db:update_host_data_for_2020_season'].invoke

      puts 'Load all shifts'
      Rake::Task['db:load_2020_shifts'].invoke

      puts "Shift Count Before Meetings: #{Shift.count}"

      # re-uses meeting load from 2019 rake file...
      puts 'Load all Meeting Shifts For Users'
      Rake::Task['db:load_meetings'].invoke

      puts 'initialize all user accounts for start of year'
      User.reset_all_accounts

      puts 'set my password'
      # set my password
      u = User.find_by(email: 'aamaxworks@gmail.com')
      u.password = ENV['AAMAX_PGPASS']

      # confirm info
      u.confirmed = true

      u.start_year = 2010
      u.save

      puts 'initialize host hauler data for 2020'
      Rake::Task['db:initialize_2020_host_hauler'].invoke
    end
    puts "Active User Count #{User.active_users.count}"
    puts "Shift Count: #{Shift.count}"

    puts "Team Leaders: #{User.team_leader_count}"
    puts "Seniors: #{User.group1.count - User.team_leader_count}"
    puts "Juniors: #{User.group2.count}"
    puts "Freshmen: #{User.group3.count}"
    puts "Rookies: #{User.rookies.count}"

    puts "DONE WITH SEASON PREP... 2020"
  end

  desc "populate shift types"
  task :load_2020_shift_types => :environment do
    # load up file
    filename = "lib/data/shift_type_2020.csv"
    if File.exists?(filename)
      puts "loading shift type data..."
      CSV.foreach(filename, :headers => true) do |row|
        hash = row.to_hash

        next if hash['short_name'].nil?
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

  desc "populate sys config settings for 2020"
  task :setup_config_for_2020 => :environment do
    puts "purging existing sys config record from system..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sys_configs RESTART IDENTITY;")
    c = SysConfig.new
    c.season_year = 2020
    c.group_1_year = 2015
    c.group_2_year = 2016
    c.group_3_year = 2017

    c.season_start_date = Date.new(2020, 11, 01)
    c.bingo_start_date = Date.new(2020, 11, 23)
    c.shift_count = 250  # TODO adjust up after bingo is done...

    if !c.save
      puts "error saving config record #{c.errors.messages}"
    end
    puts "Done with setting up System Config."
  end

  desc "populate shifts"
  task :load_2020_shifts => :environment do
    a1_shift = ShiftType.find_by(short_name: 'A1')
    tl_shift = ShiftType.find_by(short_name: 'TL')
    oc_shift = ShiftType.find_by(short_name: 'OC')

    jc_user = User.find_by(email: COTTER_EMAIL)

    if a1_shift.nil? || tl_shift.nil? || oc_shift.nil?
      raise('Shift Type Not Found')
    end

    start_date = '2020-11-30'.to_date
    end_date = '2020-12-17'.to_date
    (start_date..end_date).each do |dt|
      if ((dt >= '2020-11-30'.to_date) && (dt <= '2020-12-06'.to_date)) ||
          ((dt >= '2020-12-09'.to_date) && (dt <= '2020-12-11'.to_date))
        create_shift(tl_shift, dt, jc_user.id)
        create_shift(a1_shift, dt)
      end

      if (dt >= '2020-12-07'.to_date) && (dt <= '2020-12-08'.to_date)
        create_shift(a1_shift, dt)
        create_shift(a1_shift, dt)
      end

      if (dt >= '2020-12-12'.to_date) && (dt <= '2020-12-13'.to_date) ||
          (dt == '2020-12-16'.to_date) || (dt == '2020-12-17'.to_date)
        create_shift(tl_shift, dt, jc_user.id)
        2.times do
          create_shift(a1_shift, dt)
        end
      end

      if (dt >= '2020-12-14'.to_date) && (dt <= '2020-12-15'.to_date)
        3.times do
          create_shift(a1_shift, dt)
        end
      end

      3.times do
        create_shift(oc_shift, dt)
      end
    end

    # 12/18 - 4/4 4 A1 shifts, 1 TL shift, 5 OC shifts
    #         if day is Fri, Sat, Sun: 5 more OC shifts
    #         dates:  12-23 through 1-3, 1/18, 2/15: 5 more OC shifts
    start_date = '2020-12-18'.to_date
    end_date = '2021-04-04'.to_date
    (start_date..end_date).each do |dt|

      # if Fri - Sun... john gets an A1 and 3 unassigned - else 4 unassigned
      if ((dt.wday == 0) || (dt.wday == 5) || (dt.wday == 6))
        create_shift(a1_shift, dt, jc_user.id)
        3.times do
          create_shift(a1_shift, dt)
        end
      else
        4.times do
          create_shift(a1_shift, dt)
        end
      end

      if ((dt.wday >= 3) && (dt.wday <= 4))
        create_shift(tl_shift, dt, jc_user.id)
      else
        create_shift(tl_shift, dt)
      end

      num_on_call = 5
      if (dt.wday == 5) || (dt.wday == 6) || (dt.wday == 0) ||
          ((dt.month == 12) && (dt.year == 2020) && (dt.strftime('%d').to_i >= 23)) ||
          ((dt.month == 1) && (dt.year == 2021) && (dt.strftime('%d').to_i >= 1) && (dt.strftime('%d').to_i <= 3)) ||

          ((dt.strftime('%Y%m%d') == '20210118') || (dt.strftime('%Y%m%d') == '20210215'))
        num_on_call = 10
      end
      num_on_call.times do
          create_shift(oc_shift, dt)
      end
    end
    puts "done loading shift data: #{Shift.count}"
  end

  desc 'update host data for current season'
  task :update_host_data_for_2020_season => :environment do
#    ***************************************
#   Red Shirting
#    ***************************************

#     Brandon	Neiman
    usr = User.find_by(email: 'brneiman@comcast.net')
    usr.active_user = false
    usr.save

#     Michael	Marker
    usr = User.find_by(email: 'mmarkr@aol.com')
    usr.active_user = false
    usr.save

#     Jarret	Hallas
    usr = User.find_by(email: 'yinyangyikes@gmail.com')
    usr.active_user = false
    usr.save

#     Judy 	Calhoun
    usr = User.find_by(email: 'jcal57@yahoo.com')
    usr.active_user = false
    usr.save

#     Kay	Tran
    usr = User.find_by(email: 'ktranvt@comcast.net')
    usr.active_user = false
    usr.save


#    ***************************************
#    Retired *******************************
#    ***************************************

#    Garth	Driggs
    usr = User.find_by(email: 'garthdriggs@gmail.com')
    usr.active_user = false
    usr.save

    # Lee	Bethers
    usr = User.find_by(email: 'leebethersxx@gmail.com')
    usr.active_user = false
    usr.save

    # Kevin	Cullen
    usr = User.find_by(email: 'kevin@logocompany.net')
    usr.active_user = false
    usr.save

    # Richard	Vollmer
    usr = User.find_by(email: 'rmj_vollmer@msn.com')
    usr.active_user = false
    usr.save

    # Catherine	McEnroe
    usr = User.find_by(email: 'cathmaclaughs@me.com')
    usr.active_user = false
    usr.save

    # Azim	Merali
    usr = User.find_by(email: 'azimmerali@gmail.com')
    usr.active_user = false
    usr.save
  end

  desc 'initialize host hauler'
  task :initialize_2020_host_hauler => :environment do
    jc = User.find_by(email: 'jecotterii@gmail.com')
    (Date.parse('2020-12-01')..Date.parse('2021-04-03')).each do |dt|
      if dt.wednesday? || dt.thursday? || dt.friday? || dt.saturday? || dt.sunday?
        HostHauler.add_hauler(dt, jc.id)
      else
        HostHauler.add_hauler(dt)
      end
    end
    puts 'Done adding initial host hauler dates and seats...'
  end


  def create_shift(shift_type, dt, usr_id = nil)
    shift_type_id = shift_type.id
    st = {
        shift_type_id: shift_type_id,
        shift_status_id: 1,
        shift_date: dt,
        user_id: usr_id
    }
    if !Shift.create(st)
      puts "ERROR\n    short_name: #{shift_short_name}\n------------\n\n"
      raise 'error loading shifts'
    end
  end


end