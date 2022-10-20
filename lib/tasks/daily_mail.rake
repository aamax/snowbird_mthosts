namespace :daily do

  desc "mail all users for tomorrows shifts"
  task :mail_hosts_for_tomorow => :environment do
    dt = Date.tomorrow

    emailaddress = User.get_host_emails_for_date(dt)

    # if !emailaddress.blank?
    #   emailaddress += ",aamaxworks@gmail.com"
    # end

    # emailaddress = 'aamaxworks@gmail.com'

    @subject = "REMINDER: you are scheduled to work at Snowbird tomorrow!"
    @fromaddress = 'no-reply@snowbirdhosts.com'
    @message = "Just a friendly reminder that you are scheduled to work a shift at the Bird tomorrow.  Don't be late!"

    # if emailaddress.blank?
    #   @subject = "NO EMAILS TO SEND WORK NOTICE TO"
    #   emailaddress = 'aamaxworks@gmail.com'
    #   @message = "test email - sent only to aaMax.  kill the cron job if you keep getting these!"
    # end
    exit(0) if emailaddress.blank?

    UserNotifierMailer.send_shift_reminder(emailaddress, @fromaddress, @subject, @message).deliver unless msg.nil?


    # old email using gmail
    # msg = UserMailer.send_daily_email(emailaddress, @fromaddress, @subject, @message)
    # msg.deliver unless msg.nil?


    # TODO: send text message?
    # Rails.application.config.action_mailer
  end
end

