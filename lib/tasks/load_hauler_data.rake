namespace :db do

  desc 'set 2017 host hauler data'
  task :set_hauler_data => :environment do
    cotter = User.find_by(email: 'jecotterii@gmail.com')
    if cotter.nil?
      puts "ERROR - Cotter account not found.  Aborted."
      return
    end

# HostHauler
#  driver_id  :integer
#  haul_date  :date

# Rider
#  host_hauler_id :integer
#  user_id        :integer

    (Date.today..Date.today + 5.days).each do |dt|
      puts "populating #{dt.to_s}"

      hauler = HostHauler.create(driver_id: cotter.id, haul_date: dt)
      (1..14).each do |host|
        Rider.create(host_hauler_id: hauler.id)
      end
    end

    puts "\n\n*****************"
    HostHauler.all.each do |hauler|
      puts "hauler on: #{hauler.haul_date.to_s}"
      puts "     riders: #{hauler.riders.count}"
      puts "          #{hauler.riders.map {|r| r.user_id }.join(",")}"
    end
  end
end


