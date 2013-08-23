require 'csv'

DEFAULT_PASSWORD = "password"

namespace :db do
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

        if !User.create(u)
          puts "failed: #{u}"
        else
          if hash['admin'] == 'TRUE'
            u.add_role :admin
          end
          if hash['teamleader'] == 'TRUE'
            u.add_role :team_leader
          end
        end
      end
    else
      puts "user loader file not found"
    end
  end
end

