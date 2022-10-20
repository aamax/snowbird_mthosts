class UserNotifierMailer < ApplicationMailer
  default :from => 'snowbirdhosts@gmail.com'

  def send_shift_reminder(address, from, subject, message)
    mail(to: address,
         subject: "REMINDER: you are scheduled to work at Snowbird tomorrow!")
  end
end

