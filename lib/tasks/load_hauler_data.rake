def create_haul(cotter, dt)
  hauler = HostHauler.create(driver_id: cotter.id, haul_date: dt)
  (1..14).each do |host|
    Rider.create(host_hauler_id: hauler.id)
  end
end

def date_is_van_day(dt)
  (dt < Date.parse('2018-01-02')) || dt.friday? || dt.saturday? || dt.sunday?
end

namespace :hauler do
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

  desc 'remove 14th seat if empty in haulers'
  task :shorten_vans => :environment do
    lost_seats = 0
    lost_hosts = []
    HostHauler.where('haul_date >= ?', Date.today).each do |hauler|
      while hauler.riders.count > 10
        if hauler.open_seat_count > 0
          hauler.remove_empty_seat
          puts "strip this one: #{hauler.haul_date}.  has #{hauler.riders.count} total seats and #{hauler.open_seat_count} open."
        else
          puts "no open seats: #{hauler.haul_date} has #{hauler.riders.count}"
          r = hauler.riders.order(created_at: :desc).last
          lost_seats += 1
          lost_hosts <<{user: r.user.name, email: r.user.email, date: hauler.haul_date}
          r.delete
        end
        hauler.reload
      end

      puts "Hauler done.  Total Seats: #{hauler.riders.count}  Open Seats: #{hauler.open_seat_count}"
      puts "------------------------------------------\n"
    end

    email_list = lost_hosts.map {|r| r[:email]}.uniq
    puts "seats lost: #{lost_seats}"
    puts "hosts lost: #{email_list.count}"
    puts email_list.uniq.join(',')
  end


  desc 'add to 13 passengers in all vans from current date on...'
  task :lengthen_vans => :environment do
    HostHauler.where('haul_date >= ?', Date.today).each do |hauler|
      added_cnt = 0
      while hauler.riders.count < 13
        Rider.create(host_hauler_id: hauler.id)
        added_cnt += 1
        hauler.reload
      end

      puts "Hauler done.  Total Seats: #{hauler.riders.count}  Open Seats: #{hauler.open_seat_count} added seats: #{added_cnt}"
      puts "------------------------------------------\n"
    end
    puts "done adjust seats up..."
  end


end


