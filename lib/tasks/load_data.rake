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

        u = {name: hash["name"], email: hash["email"], password: DEFAULT_PASSWORD, active_user: true, start_year: hash["startdate"]}
        if !User.create(u)
          puts "failed: #{u}"
        end
      end

    else
      puts "user loader file not found"
    end
  end
end

