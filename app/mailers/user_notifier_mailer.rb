class UserNotifierMailer < ApplicationMailer
  default :from => 'snowbirdhosts@gmail.com'

  def send_shift_reminder_email(address)
    mail(to: address,
         subject: "REMINDER: you are scheduled to work at Snowbird tomorrow!")
  end

  def send_email(address, from, subject, message)
    mail(to: address, subject: "[#{from}] - #{subject}") do |format|
      format.html { render html: message.html_safe }
    end
  end
end

