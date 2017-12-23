def create_haul(cotter, dt)
  hauler = HostHauler.create(driver_id: cotter.id, haul_date: dt)
  (1..14).each do |host|
    Rider.create(host_hauler_id: hauler.id)
  end
end

def date_is_van_day(dt)
  (dt < Date.parse('2018-01-02')) || dt.friday? || dt.saturday? || dt.sunday?
end

namespace :db do
  desc 'set 2017 host hauler data'
  task :set_hauler_data => :environment do
    cotter = User.find_by(email: 'jecotterii@gmail.com')
    if cotter.nil?
      puts "ERROR - Cotter account not found.  Aborted."
      return
    end

    HostHauler.delete_all
    Rider.delete_all

    end_date = Date.parse('2018-05-28')

    (Date.today..end_date).each do |dt|

      if date_is_van_day(dt)
        puts "populating #{dt.to_s}"

        create_haul(cotter, dt)
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


