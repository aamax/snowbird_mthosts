require 'csv'

DEFAULT_PASSWORD = "password"

namespace :db do

  desc "populate users"
  task :load_all_data => :environment do
    Rake::Task['db:load_users'].invoke

    Rake::Task['db:load_shift_types'].invoke
  end

  desc "populate users"
  task :load_users => :environment do
    # clear out users
    puts "purging existing users from system..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE users RESTART IDENTITY;")

    # load up file
    filename = "lib/data/hostdata.csv"

    if File.exists?(filename)
      puts "loading user data..."
      CSV.foreach(filename, :headers => true) do |row|
        hash = row.to_hash
        u = {
            name: hash["name"], email: hash["email"], password: DEFAULT_PASSWORD, active_user: true,
            start_year: hash["startdate"].to_i, street: hash['street'], city: hash['city'], state: hash['state'],
            zip: hash['zip'], home_phone: hash['homephone'], cell_phone: hash['cellphone'], alt_email: '',
            notes: hash['notes'], confirmed: false, nickname: ''
            }
        usr = User.create(u)
        if (usr == false) || usr.nil?
          puts "failed: #{u}"
        else
          if hash['admin'] && (hash['admin'].upcase == 'TRUE')
            usr.add_role :admin
          end
          if hash['teamleader'] && (hash['teamleader'].upcase == 'TRUE')
            usr.add_role :team_leader
          end
        end
      end
      puts "done loading user data"
    else
      puts "user loader file not found"
    end
  end


  desc "populate users"
  task :load_shift_types => :environment do
    # clear out users
    puts "purging existing shift types from system..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE shift_types RESTART IDENTITY;")

    # load up file
    filename = "lib/data/shift_type_data.csv"

    if File.exists?(filename)
      puts "loading shift type data..."
      CSV.foreach(filename, :headers => true) do |row|
        hash = row.to_hash

        sdarr = hash['starttime'].split(' ')
        edarr = hash['endtime'].split(' ')
        st = {
            short_name: hash["shortname"], description: hash["description"], start_time: sdarr[1],
            end_time: edarr[1], tasks: hash['speedcontrol']
        }

        if !ShiftType.create(st)
          puts "failed: #{st}"
        end
      end

      puts "done loading shift type data"
    else
      puts "shift type loader file not found"
    end
  end

end

