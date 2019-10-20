require 'csv'

DEFAULT_PASSWORD = "password"

namespace :db do

  desc "load all data"
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

      # puts 'Loading shift types'
      # Rake::Task['db:load_shift_types'].invoke

      # set roles for OGOMT hosts
      set_ogomt_roles
      set_survey_roles

      puts 'load 2019 rookies into system'
      Rake::Task['db:load_2019_rookies'].invoke

      puts 'set up configs for season'
      Rake::Task['db:setup_config_for_2019'].invoke

      puts 'Load all shifts'
      Rake::Task['db:load_shifts'].invoke

      puts 'Load all Ongoing Training Shifts'
      Rake::Task['db:load_ongoing_training_shifts']



      puts "Shift Count Before Meetings: #{Shift.count}"

      puts 'Load all Meeting Shifts For Users'
      Rake::Task['db:load_meetings'].invoke

      populate_carol_hoban_2019_surveys

      populate_2019_trainings

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
          usr = User.new(name: "#{row[0].strip} #{hash['last']}", email: hash['email'],
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
          usr.update_attributes(name: "#{row[0].strip} #{hash['last']}", email: hash['email'],
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

      usr = User.find_by(email: 'garthdriggs@gmail.com')
      usr.active_user = true
      usr.start_year = 2019
      puts "USER: #{usr.inspect}"
      if !usr.valid?
        puts "\nERRROR in data:  #{usr.errors.messages}\n#{usr.inspect}\n-----\n#{hash}\n\n"
      else
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
    c.group_2_year = 2017
    c.group_3_year = 2018
    c.season_start_date = Date.new(2019, 10, 01)
    c.bingo_start_date = Date.new(2019, 11, 04)

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

  desc "populate ongoing_training shifts"
  task :load_ongoing_training_shifts => :environment do
    # create all training dates
    # create 1 trainer and 3 trainees on each
    # set trainer host for each

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

  def set_ogomt_roles
    paul = User.find_by(email: 'altasnow@gmail.com')
    paul.add_role :ongoing_trainer

    chris = User.find_by(email: 'krishill0@gmail.com')
    chris.add_role :ongoing_trainer

    sara = User.find_by(email: 'sarah3884@yahoo.com')
    sara.add_role :ongoing_trainer

    eric = User.find_by(email: 'snowsawyer@hotmail.com')
    eric.add_role :ongoing_trainer
  end

  def set_survey_roles
    carol = User.find_by(email: 'cshobie1@msn.com')
    carol.add_role :surveyor
  end

  def populate_carol_hoban_2019_surveys
    puts "Loading Carol Hobans Survey Shifts..."
    carol = User.find_by(email: 'cshobie1@msn.com')
    dates = %w['2019-12-13' '2020-01-03' '2020-01-07' '2020-01-13' '2020-01-20' '2020-01-24' '2020-01-30' '2020-02-03'
        '2020-02-05' '2020-02-11' '2020-02-19' '2020-02-21' '2020-02-27' '2020-03-02' '2020-03-12' '2020-03-16'
        '2020-03-24' '2020-03-30']
    dates.each do |date|
      shift = Shift.where("short_name = 'SV' and shift_date = #{date}").first
      shift.user_id = carol.id
      shift.save
    end
    puts "Done loading Carols shifts."
  end

  def populate_2019_trainings
    puts 'Populating 2019 training shifts...'
    filename = 'lib/data/2019_trainings.csv'
    trainers = { 118 => User.find_by(id: 118),
                  61 => User.find_by(id: 61),
                  42 => User.find_by(id: 42),
                  118 => User.find_by(id: 118),
                  131 => User.find_by(id: 131) }
    CSV.foreach(filename, :headers => true) do |row|
      hash = row.to_hash
      dt = TrainingDate.create(shift_date: hash['date'])

      OngoingTraining.create(training_date_id: dt.id, user_id: trainers[hash['trainer'].to_i].id, is_trainer: true)
      OngoingTraining.create(training_date_id: dt.id, is_trainer: false)
      OngoingTraining.create(training_date_id: dt.id, is_trainer: false)
      OngoingTraining.create(training_date_id: dt.id, is_trainer: false)
    end
    puts "Done Populating training shifts: Dates: #{TrainingDate.count} - Shifts: #{OngoingTraining.count}"
  end
end

