namespace :work do


  task :send_mail_test => :environment do
    # using SendGrid's Ruby Library
    # https://github.com/sendgrid/sendgrid-ruby
    require 'sendgrid-ruby'
    include SendGrid

    from = Email.new(email: 'test@example.com')
    to = Email.new(email: 'aamaxworks@gmail.com')
    subject = 'Sending with SendGrid is Fun'
    content = Content.new(type: 'text/plain', value: 'and easy to do anywhere, even with Ruby')
    mail = Mail.new(from, subject, to, content)

    puts mail.to_json

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._('send').post(request_body: mail.to_json)
    puts response.status_code
    puts response.body
    puts response.headers
  end


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

  task :fix_haulers => :environment do
    puts "starting..."
    emails = []
    haulers = HostHauler.where("haul_date > ?", Date.today)
    haulers.find_each do |hauler|
      while (hauler.riders.count > 10) #&& hauler.riders.last.user_id.nil?
        if !hauler.riders.last.nil? && !hauler.riders.last.user_id.nil?
          emails << hauler.riders.last.user.email
        end
        hauler.riders.last.destroy

      end
    end

    puts emails.uniq!

    puts "done... "
  end

end
