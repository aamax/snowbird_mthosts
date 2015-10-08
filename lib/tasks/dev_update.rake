namespace :data do
  task :add_year => :environment do
    puts "adding a year to shift data..."

    Shift.all.each do |s|
      s.shift_date = s.shift_date + 1.year
      s.save
    end

    puts "done..."
  end

  task :add_shortname => :environment do
    puts "adding shortname to all shifts"

    Shift.all.each do |s|
      s.short_name = s.shift_type.short_name[0..1]
      s.save
    end
    puts "done adding short names..."
  end
end