namespace :daily do

  desc "mail all users for tomorrows shifts"
  task :mail_hosts_for_tomorow => :environment do
    dt = Date.tomorrow
    users = Shift.where(shift_date: dt).map {|s| s.user }
    emailaddress = users.compact.map {|u| u.email}.join(',')


    @subject = "REMINDER: you are scheduled to work at Snowbird tomorrow!"
    @fromaddress = 'no-reply@snowbirdhosts.com'
    @message = "Just a friendly reminder that you are scheduled to work a shift at the Bird tommorrow.  Don't be late!"

    exit(0) if emailaddress.blank?

    msg = UserMailer.send_daily_email(emailaddress, @fromaddress, @subject, @message)
    msg.deliver unless msg.nil?

    # TODO: send text message?

  end
end

