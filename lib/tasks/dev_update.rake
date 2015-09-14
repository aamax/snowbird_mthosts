namespace :data do
  task :add_year => :environment do
    puts "adding a year to shift data..."

    Shift.all.each do |s|
      s.shift_date = s.shift_date + 1.year
      s.save
    end

    puts "done..."
  end
end