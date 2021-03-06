require 'csv'


namespace :db do
  desc "load all 2019 data"
  task :load_all_data => :environment do
    ActiveRecord::Base.transaction do
      # clear all data
      puts "Clearing all data: riders, host_haulers, shfits, shift_logs, shift_types"
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE riders RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE host_haulers RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shifts RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE shift_logs RESTART IDENTITY;")
      # ActiveRecord::Base.connection.execute("TRUNCATE TABLE shift_types RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE ongoing_trainings RESTART IDENTITY;")
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE training_dates RESTART IDENTITY;")

      if ShiftType.find_by(short_name: 'OT').nil?
        ShiftType.create(short_name: 'OT', description: 'OGOMT Ongoing On Mountain Training',
                         start_time: '08:00', end_time: '12:00', tasks: 'Training as Needed')
      end

      # puts 'Loading shift types'
      # Rake::Task['db:load_shift_types'].invoke

      puts 'load 2019 rookies into system'
      Rake::Task['db:load_2019_rookies'].invoke

      puts 'set up configs for season'
      Rake::Task['db:setup_config_for_2019'].invoke

      puts 'make host updates for current season'
      Rake::Task['db:update_host_data_for_season'].invoke

      puts 'Load all shifts'
      Rake::Task['db:load_shifts'].invoke

      puts 'Load all Ongoing Training Shifts'
      Rake::Task['db:load_ongoing_training_shifts'].invoke

      puts 'Populate Surveyor Shifts'
      Rake::Task['db:populate_surveyor_shifts'].invoke

      puts "Shift Count Before Meetings: #{Shift.count}"

      puts 'Load all Meeting Shifts For Users'
      Rake::Task['db:load_meetings'].invoke

      puts 'Make targetted adjustments for 2019'
      Rake::Task['db:make_2019_adjustments'].invoke

      puts 'initialize all user accounts for start of year'
      User.reset_all_accounts

      puts 'set my password'
      # set my password
      u = User.find_by(email: 'aamaxworks@gmail.com')
      u.password = ENV['AAMAX_PGPASS']
      u.save

      puts 'initialize host hauler data for 2020'
      Rake::Task['db:initialize_host_hauler'].invoke
    end
    puts "Active User Count #{User.active_users.count}"
    puts "Shift Count: #{Shift.count}"

    puts "Seniors: #{User.group1.count}"
    puts "Juniors: #{User.group2.count}"
    puts "Freshmen: #{User.group3.count}"
    puts "Rookies: #{User.rookies.count}"

    puts "DONE WITH SEASON PREP... 2019"
  end

  desc 'load 2019 rookies'
  task :load_2019_rookies => :environment do
    filename = "lib/data/rookies_2019.csv"
    ADDRESS_FORMAT = /([a-zA-Z0-9 ]+), ([a-zA-Z0-9]+), ([a-zA-Z0-9]+) ([0-9]+)/

    rookie_count = 0
    if File.exists?(filename)
      puts "loading 2019 rookie data..."
      CSV.foreach(filename, :headers => true) do |row|
        hash = row.to_hash
        usr = User.find_by(email: hash['email'])
        rookie_count += 1

        if usr.nil?
          puts "\n\nrookie not found...#{hash['email']}\n"
          arr = hash['address'].match(ADDRESS_FORMAT)
          street_value = arr[1]
          city_value = arr[2]
          state_value = arr[3]
          zip_value = arr[4]
          host_name = "#{clean_string(row[0])} #{clean_string(hash['last'])}"
          usr = User.new(name: host_name, email: hash['email'],
                         cell_phone: hash['mobile'], home_phone: hash['home'],
                         street: street_value, city: city_value,
                         state: state_value, zip: zip_value, password: '5teep&Deep')
          usr.active_user = true
          usr.start_year = 2019
          usr.snowbird_start_year = 2019
        else
          puts "\n\nfound rookie before add: #{hash['email']}\n    #{usr.inspect}\n\n"

          arr = hash['address'].match(ADDRESS_FORMAT)
          street_value = arr[1]
          city_value = arr[2]
          state_value = arr[3]
          zip_value = arr[4]
          host_name = "#{clean_string(row[0])} #{clean_string(hash['last'])}"
          usr.update_attributes(name: host_name, email: hash['email'],
                         cell_phone: hash['mobile'], home_phone: hash['home'],
                         street: street_value, city: city_value,
                         state: state_value, zip: zip_value, password: '5teep&Deep',
                         start_year: 2019)
        end

        puts "USER: #{usr.inspect}"
        if !usr.valid?
          puts "\nERRROR in data:  #{usr.errors.messages}\n#{usr.inspect}\n-----\n#{hash}\n\n"
          next
        end
        usr.save
      end
    else
      puts "\n\n****************\nWARNING:  NO ROOKIE FILE FOUND!\n***************\n\n"
    end

    puts "DONE WITH ROOKIE LOAD... Loaded #{rookie_count} Rookies."
  end

  desc "populate shift types"
  task :load_shift_types => :environment do
    # load up file
    filename = "lib/data/shift_type_2018.csv"

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

  desc 'load all meetings and add to users'
  task :load_meetings => :environment do
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

  desc "populate sys config settings for 2018"
  task :setup_config_for_2019 => :environment do
    puts "purging existing sys config record from system..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE sys_configs RESTART IDENTITY;")
    c = SysConfig.new
    c.season_year = 2019
    c.group_1_year = 2014
    c.group_2_year = 2016
    c.group_3_year = 2017
    c.season_start_date = Date.new(2019, 10, 01)
    c.bingo_start_date = Date.new(2019, 11, 11)
    c.shift_count = 250  # TODO adjust up after bingo is done...

    if !c.save
      puts "error saving config record #{c.errors.messages}"
    end
    puts "Done with setting up System Config."
  end

  desc "populate shifts"
  task :load_shifts => :environment do
    # load up file
    filename = "lib/data/shift_data.csv"

    if File.exists?(filename)
      puts "loading shift data..."
      CSV.foreach(filename, :headers => true) do |row|
        hash = row.to_hash

        next if hash['start_date'].nil? || (hash['start_date'][0] == '#')

        start_date = hash['start_date'].to_date
        if hash['end_date']
          end_date = hash['end_date'].to_date
        else
          end_date = start_date
        end

        shift_type_id = nil
        tag = hash['short_name']

        case tag
        when 'A1','TL','C1weekend','C2weekend','C3weekend','C4weekend', 'SV' #, 'hidden_weekday'
          if ShiftType.find_by(short_name: tag).nil?
            binding.pry
          end

          shift_type_id = ShiftType.find_by(short_name: tag).id
          if tag == 'SV'
            end_date = start_date
          end
        end
        (start_date..end_date).each do |dt|
          case shift_type_id
          when nil
            case tag
            when 'SV_range'
              create_shift('SV', dt)
            when 'hidden_weekday'
              if (dt.monday? || dt.tuesday? || dt.wednesday? || dt.thursday?) && (not_holiday(dt))
                create_shift('H1weekday', dt)
              end
            when 'holiday'
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
              create_shift('C1weekend', dt)
              create_shift('C2weekend', dt)
              create_shift('C3weekend', dt)
              create_shift('C4weekend', dt)
              create_shift('SV', dt)
            when 'regular'
              if dt.friday?
                create_shift('P1friday', dt)
                create_shift('P2friday', dt)
                create_shift('P3friday', dt)
                create_shift('P4friday', dt)
                create_shift('H1friday', dt)
                create_shift('H1friday', dt)
                create_shift('G1friday', dt)
                create_shift('G2friday', dt)
                create_shift('G3friday', dt)
                create_shift('G4friday', dt)

                # create_shift('SV', dt)
              elsif dt.saturday? || dt.sunday?
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
                create_shift('C1weekend', dt)
                create_shift('C2weekend', dt)
                create_shift('C3weekend', dt)
                create_shift('C4weekend', dt)

                # create_shift('SV', dt)
              else
                create_shift('P1weekday', dt)
                create_shift('P2weekday', dt)
                create_shift('P3weekday', dt)
                create_shift('P4weekday', dt)
                create_shift('H1weekday', dt)

              end
            when 'regular_no_survey'
              if dt.friday?
                create_shift('P1friday', dt)
                create_shift('P2friday', dt)
                create_shift('P3friday', dt)
                create_shift('P4friday', dt)
                create_shift('H1friday', dt)
                create_shift('H1friday', dt)
                create_shift('G1friday', dt)
                create_shift('G2friday', dt)
                create_shift('G3friday', dt)
                create_shift('G4friday', dt)

              elsif dt.saturday? || dt.sunday?
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
                create_shift('C1weekend', dt)
                create_shift('C2weekend', dt)
                create_shift('C3weekend', dt)
                create_shift('C4weekend', dt)

              else
                create_shift('P1weekday', dt)
                create_shift('P2weekday', dt)
                create_shift('P3weekday', dt)
                create_shift('P4weekday', dt)
                # create_shift('H1weekday', dt)
              end
            when 'holiday_floats'
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
              create_shift('F1weekend', dt)
              create_shift('F2weekend', dt)
              create_shift('F3weekend', dt)
              create_shift('F4weekend', dt)
              create_shift('SV', dt)
            when 'holiday_floats_no_survey'
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
              create_shift('F1weekend', dt)
              create_shift('F2weekend', dt)
              create_shift('F3weekend', dt)
              create_shift('F4weekend', dt)
            when 'end_of_season'
               if dt.friday? || dt.saturday? || dt.sunday? || dt.strftime('%Y%m%d') == '20200525'
                create_shift('A1', dt)
                create_shift('A1', dt)
                create_shift('TL', dt)
               end
            when 'regular_weekday'
              if (dt.monday? || dt.tuesday? || dt.wednesday? || dt.thursday?) && (not_holiday(dt))
                create_shift('P1weekday', dt)
                create_shift('P2weekday', dt)
                create_shift('P3weekday', dt)
                create_shift('P4weekday', dt)
              elsif dt.friday?
                create_shift('P1friday', dt)
                create_shift('P2friday', dt)
                create_shift('P3friday', dt)
                create_shift('P4friday', dt)
                create_shift('H1friday', dt)
                create_shift('H1friday', dt)
                create_shift('G1friday', dt)
                create_shift('G2friday', dt)
                create_shift('G3friday', dt)
                create_shift('G4friday', dt)
              end
            when 't1day'
              create_shift_with_host('TR', dt, hash['host_id'])

              create_shift('T1', dt)
              create_shift('T1', dt)
              create_shift('T1', dt)
            when 't2day'
              create_shift_with_host('TR', dt, hash['host_id'])

              create_shift('T2', dt)
              create_shift('T2', dt)
              create_shift('T2', dt)
            when 't3day'
              create_shift_with_host('TR', dt, hash['host_id'])

              create_shift('T3', dt)
              create_shift('T3', dt)
              create_shift('T3', dt)
            when 't4day'
              create_shift_with_host('TR', dt, hash['host_id'])

              create_shift('T4', dt)
              create_shift('T4', dt)
              create_shift('T4', dt)
            end
          else
            st = {
                shift_type_id: shift_type_id,
                shift_status_id: 1,
                shift_date: dt
            }

            if !Shift.create(st)
              puts "ERROR\n    hash: #{hash.inspect}\n------------\n\n"
              raise 'error loading shifts'
            end
          end
        end
      end
      puts "done loading shift data: #{Shift.count}"
    else
      puts "ERROR: shift loader file not found"
    end
  end

  desc "populate surveyor shifts"
  task :populate_surveyor_shifts => :environment do
    puts 'populating survey shifts rake task start...'
    bErrors = false
    filename = 'lib/data/2019_surveys.csv'
    surveyors = { 103 => User.find_by(id: 103), # Adam Vance
                  147 => User.find_by(id: 147), # Carla Merrill
                  8 => User.find_by(id: 8),  # Carol Hoban
                  95 => User.find_by(id: 95), # Christine Gregory
                  138 => User.find_by(id: 138),  # Dotti Gallagher
                  120 => User.find_by(id: 120),  # Jenivere Stotesbery
                  115 => User.find_by(id: 115),  # Mary Ness
                  140 => User.find_by(id: 140),  # Sarah Haskin
                  135 => User.find_by(id: 135), # Judy Calhoun
                  31 => User.find_by(id: 31), # Jack Thompson
                  150 => User.find_by(id: 150), # Kay Tran
                  162 => User.find_by(id: 162) # Megan Wilson
    }

    # make sure surveyor roles are updated
    puts 'updating surveyor role values'
    User.all.each do |host|
      if surveyors[host.id].nil?
        host.remove_role :surveyor
      else
        host.add_role :surveyor
      end
    end

    # set surveyor shift hosts
    puts 'setting the hosts to all assigned surveyor shifts'
    CSV.foreach(filename, :headers => true) do |row|
      hash = row.to_hash
      qry = "short_name = 'SV' and user_id is null and shift_date = '#{row[0]}'"
      shift = Shift.where(qry).first
      if shift.nil?
        puts '***********************'
        puts "ERROR: Shift not found: #{qry}"
        puts "-------------------------"
        bErrors = true
        next
      end

      shift.user = surveyors[hash['host_id'].to_i]

      if !shift.save
        puts "***********************"
        puts 'ERROR setting survey shift'
        puts "shift: #{shift.inspect}\nrow: #{hash}\nERROR: #{shift.errors.inspect}"
        puts "***********************\n\n"
        bErrors = true
      end
    end
    puts "Done setting surveyor shifts with #{ bErrors ? '' : 'OUT'} errors"
  end

  desc "populate ongoing_training shifts"
  task :load_ongoing_training_shifts => :environment do
    puts '    set roles for ogom trainers...'
    trainers = { 118 => User.find_by(id: 118),
                 61 => User.find_by(id: 61),
                 42 => User.find_by(id: 42),
                 131 => User.find_by(id: 131) }
    trainers.each do |key, value|
      value.add_role :ongoing_trainer
    end

    puts 'Populating 2019 OGOM training shifts...'
    filename = 'lib/data/2019_trainings.csv'

    CSV.foreach(filename, :headers => true) do |row|
      hash = row.to_hash
      dt = TrainingDate.create(shift_date: hash['date'])

      OngoingTraining.create(training_date_id: dt.id, user_id: trainers[hash['trainer'].to_i].id, is_trainer: true)
      OngoingTraining.create(training_date_id: dt.id, is_trainer: false)
      OngoingTraining.create(training_date_id: dt.id, is_trainer: false)
      OngoingTraining.create(training_date_id: dt.id, is_trainer: false)
    end
    puts "Done Populating OGOM training shifts: Dates: #{TrainingDate.count} - Shifts: #{OngoingTraining.count}"
  end

  desc 'initialize host hauler'
  task :initialize_host_hauler => :environment do
    jc = User.find_by(email: 'jecotterii@gmail.com')
    (Date.parse('2019-11-23')..Date.parse('2020-05-27')).each do |dt|
      if dt.thursday? || dt.friday? || dt.saturday? || dt.sunday?
        HostHauler.add_hauler(dt, jc.id)
      end
    end
    puts 'Done adding initial host hauler dates and seats...'
  end

  desc 'update host data for current season'
  task :update_host_data_for_season => :environment do

    puts 'Disable Hosts Not Returning'
    puts "   Fred Manar"
    u = User.find_by(email: 'fred_manar@hotmail.com')
    u.active_user = false
    u.save

    u = User.find_by(email: 'ellen_miller@att.net')
    u.active_user = false
    u.save

    u = User.find_by(email: 'hkbirich@gmail.com')
    u.active_user = false
    u.save

    u = User.find_by(email: 'kkweiss22@gmail.com')
    u.active_user = false
    u.save

    u = User.find_by(email: 'jvg2524@gmail.com')
    u.active_user = false
    u.save

    u = User.find_by(email: 'sternds@gmail.com')
    u.active_user = false
    u.save

    u = User.find_by(email: 'rfhall1@gmail.com')
    u.active_user = false
    u.save

    u = User.find_by(email: 'michaeldalesteffen@gmail.com')
    u.active_user = false
    u.save

    u = User.find_by(email: 'jdeisley@gmail.com')
    u.active_user = false
    u.save

    usr = User.find_by(email: 'garthdriggs@gmail.com')
    usr.active_user = true
    usr.start_year = HostConfig.group_2_year
    usr.save

    puts "set Stephen Smith as Team Leader"
    u = User.find_by(email: 'herkyp@yahoo.com')
    u.start_year = HostConfig.group_1_year
    u.save
    u.add_role :team_leader

    puts "fix Clay Mendenhal"
    u = User.find_by(email: 'claybirdm@gmail.com')
    u.start_year = HostConfig.group_1_year
    u.snowbird_start_year = 2009
    u.save

    puts 'fix huggy start year'
    u = User.find_by(email: 'yinyangyikes@gmail.com')
    u.start_year = HostConfig.group_2_year
    u.save

    puts 'fix heather start year'
    u = User.find_by(email: 'heatherhansen0125@gmail.com')
    u.start_year = HostConfig.group_2_year
    u.save

    puts 'fix troy start year'
    u = User.find_by(email: 'troybate@gmail.com')
    u.start_year = HostConfig.group_3_year
    u.save

    # Fix Bad Names
    User.all.each do |u|
      arr = u.name.split(' ')
      arr.each_with_index do |value, idx|
        arr[idx] = clean_string(value)
      end
      u.name = arr.join(' ')
      u.save
    end
  end

  desc 'make targetted adjustments for 2019 data load'
  task :make_2019_adjustments => :environment do
    puts 'remove extra training shifts from 12/14 and 12/21'
    Shift.where("shift_date = '2019-12-14' and short_name = 'T1'").first.delete
    Shift.where("shift_date = '2019-12-21' and short_name = 'T1'").first.delete

    # add training shifts for Huggy & Heater
    huggy = User.find_by(email: 'yinyangyikes@gmail.com')
    heather = User.find_by(email: 'heatherhansen0125@gmail.com')
    meetings = ShiftType.where("short_name like 'M1' or short_name like 'M3'")
    [huggy, heather].each do |u|
      meetings.each do |m|
        s_date = Date.parse(MEETINGS[m.short_name])
        new_shift = Shift.create(:user_id => u.id,
                                 :shift_type_id => m.id,
                                 :shift_date => s_date,
                                 :shift_status_id => 1,
                                 :day_of_week => s_date.strftime("%a"))
      end
    end

    # one time manual tweak on OT shift type
    puts 'change start and end time for OT shift types'
    st = ShiftType.find_by(short_name: 'OT')
    st.start_time = '0830'
    st.end_time = '1600'
    st.save
  end

  def not_holiday(dt)
    date = dt.strftime('%Y%m%d')
    (date != '20200120') && (date != '20200217')
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

  def clean_string(string)
    string.chars.reject { |char| char.ord == 160 }.join
  end


  # host update for 2018/19 season
  # puts "disabling Kate's Acount"
  # u = User.find_by(name: 'Kate')
  # u.active_user = false
  # u.save
  #
  # puts 'de-activate Gabrielle Gale'
  # u = User.find_by(email: 'gabrielle.bomgren.gale@gmail.com')
  # u.active_user = false
  # u.save
  #
  # puts 'de-activate Craig Whetman'
  # u = User.find_by(email: 'craig_whetman@hotmail.com')
  # u.active_user = false
  # u.save
  #
  # puts "set Alan Marker seniority"
  # u = User.find_by(email: 'akmarler@hotmail.com')
  # u.start_year = 2013
  # u.save
  #
  # puts "set Sarah R seniority"
  # u = User.find_by(email: 'sarah3884@yahoo.com')
  # u.start_year = 2013
  # u.save
  #
  # puts 'Setting up config for season'
  # Rake::Task['db:setup_config_for_2018'].invoke
  #
  # puts 'Loading Rookies for 2018'
  # Rake::Task['db:load_2018_rookies'].invoke
  #
  # puts 'set seniority for Karen Weiss'
  # u = User.find_by(email: 'kkweiss22@gmail.com')
  # u.start_year = 2016
  # u.snowbird_start_year = 2018
  # u.save

  # desc "evaluate shifts"
  # task :eval_shifts => :environment do
  #   dates = {}
  #   Shift.where("short_name not like 'M%'").order(:shift_date).each do |s|
  #     if dates[s.shift_date].nil?
  #       dates[s.shift_date] = 0
  #     end
  #     dates[s.shift_date] += 1
  #   end
  #   # puts "Date,Day,Count"
  #   # dates.each do |key, value|
  #   #   puts "#{key},#{key.to_date.strftime('%a')},#{value}"
  #   # end
  #   #
  #
  #   CSV.open("lib/data/shift_stats_output.csv", "w") do |csv|
  #     csv << %w[Date Day Count]
  #     num_days = 0
  #     shift_count = 0
  #     dates.each do |key, value|
  #       num_days += 1
  #       shift_count += value
  #       csv << [key,key.to_date.strftime('%a'),value]
  #     end
  #
  #     csv << ["Number of Days", num_days]
  #     csv << ["Shift Count From Totals", shift_count]
  #     csv << ["Shifts Count From DB", Shift.where("short_name not like 'M%'").count]
  #   end
  # end
  #
  # desc 'seniority eval'
  # task :eval_seniority => :environment do
  #   puts "User Count: #{User.active_users.count}\n\n"
  #
  #   CSV.open("lib/data/seniority_output.csv", "w") do |csv|
  #     csv << ['roles', 'name', 'seniority', 'start_year']
  #     User.rookies.order(:start_year).each do |u|
  #       csv << [u.roles.map(&:name).join(','), u.name, u.seniority, u.start_year]
  #     end
  #   end
  #
  #   puts "DONE"
  # end
  #
  #
  # desc "evaluate users"
  # task :eval_users => :environment do
  #   filename = 'lib/data/seniority_list.csv'
  #
  #   names = []
  #
  #   seniorities = { teamlead: 0, senior: 0, junior: 0, freshman: 0, rookie: 0 }
  #   if File.exists?(filename)
  #     puts 'reading csv file...'
  #     CSV.foreach(filename, :headers => true) do |row|
  #       hash = row.to_hash
  #
  #       name_value = "#{row[0].strip} #{row[1].strip}"
  #       name_value2 = "#{row[0].strip}  #{row[1].strip}"
  #       # puts "SEARCH: #{name_value}"
  #       u = User.where("name = '#{name_value}' or name = '#{name_value2}'").first
  #       puts "========>    Can't find #{name_value}" if u.nil?
  #
  #       seniorities[:teamlead] += 1 if u.has_role? :team_leader
  #       seniorities[:senior] += 1 if u.group_1?
  #       seniorities[:rookie] += 1 if u.rookie?
  #       seniorities[:junior] += 1 if u.group_2?
  #       seniorities[:freshman] += 1 if u.group_3? && !u.rookie?
  #
  #       names << u.name if u.group_3?
  #     end
  #
  #     puts 'freshmen'
  #     names.sort.each do |n|
  #       puts n
  #     end
  #   end

    # names = names.sort

    # cnt2 = 0
    # User.active_users.order(:name).all.each do |u|
    #   if name_list[u.name].nil?
    #     puts "Can't find: #{u.name}"
    #     cnt2 += 1
    #   else
    #     name_list[u.name] = nil
    #   end
    #
    # end
    # puts "CNT: #{cnt}"
    # puts "CNT2: #{cnt2}"
    # puts "name list: #{name_list.count}"

    # puts seniorities.inspect
    # puts "Users: #{User.active_users.count}"
  # end



    # desc 'load 2017 rookies'
  # task :load_2017_rookies => :environment do
  #   filename = "lib/data/rookies_2017.csv"
  #
  #   if File.exists?(filename)
  #     puts "loading 2017 rookie data..."
  #     CSV.foreach(filename, :headers => true) do |row|
  #       hash = row.to_hash
  #
  #       usr = User.find_by(email: hash['email'])
  #
  #       usr ||= User.new(name: "#{hash['fname']} #{hash['lname']}", email: hash['email'],
  #                        cell_phone: hash['phone'], street: hash['address'], password: '5teep&Deep')
  #       usr.active_user = true
  #       usr.start_year = 2017
  #       usr.snowbird_start_year = 2017
  #       if !usr.valid?
  #         puts "\nERRROR in data:  #{usr.errors.messages}\n\n"
  #         next
  #       end
  #
  #       puts "saving user: #{usr.inspect}\n-------------"
  #       usr.save
  #     end
  #   end
  # end
  #
  #
  # desc "populate snowbird_start_year from start_year"
  # task :set_snowbird_start_year => :environment do
  #   User.all.each do |u|
  #     u.snowbird_start_year = u.start_year
  #     u.save
  #   end
  # end
  #
  #
  # desc "populate users"
  # task :load_users => :environment do
  #   # clear out users
  #   puts "purging existing users from system..."
  #   ActiveRecord::Base.connection.execute("TRUNCATE TABLE users RESTART IDENTITY;")
  #
  #   # load up file
  #   filename = "lib/data/hostdata.csv"
  #
  #   if File.exists?(filename)
  #     puts "loading user data..."
  #     CSV.foreach(filename, :headers => true) do |row|
  #       hash = row.to_hash
  #       u = {
  #           name: hash["name"], email: hash["email"], password: DEFAULT_PASSWORD, active_user: true,
  #           start_year: hash["startdate"].to_i, street: hash['street'], city: hash['city'], state: hash['state'],
  #           zip: hash['zip'], home_phone: hash['homephone'], cell_phone: hash['cellphone'], alt_email: '',
  #           notes: hash['notes'], confirmed: false, nickname: ''
  #       }
  #       usr = User.create(u)
  #       if (usr == false) || usr.nil?
  #         puts "failed: #{u}"
  #       else
  #         if hash['admin'] && (hash['admin'].upcase == 'TRUE')
  #           usr.add_role :admin
  #         end
  #         if hash['teamleader'] && (hash['teamleader'].upcase == 'TRUE')
  #           usr.add_role :team_leader
  #         end
  #       end
  #     end
  #     puts "done loading user data"
  #   else
  #     puts "user loader file not found"
  #   end
  # end
end

