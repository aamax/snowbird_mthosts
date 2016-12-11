namespace :work do
  task :fix_friday_shifts => :environment do
    puts "starting..."

    h1f = ShiftType.where("short_name = 'H1Friday'").first
    h2f = ShiftType.where("short_name = 'H2Friday'").first

    icnt = 0
    Shift.all.each do |shift|
      next if shift.shift_date < Date.today
      next unless shift.shift_date.wday == 5
      next unless (shift.short_name == 'H1') || (shift.short_name == 'H2')



      puts "\n#{shift.inspect}"
      icnt += 1

      if shift.short_name == 'H1'
        shift.shift_type_id = h1f.id
        shift.short_name = h1f.short_name
        shift.save
      end

      if shift.short_name == 'H2'
        shift.shift_type_id = h2f.id
        shift.short_name = h2f.short_name
        shift.save
      end

    end

    puts "done... #{icnt}"
  end
end
