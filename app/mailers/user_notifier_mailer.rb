# class UserNotifierMailer < Devise::Mailer #ApplicationMailer
#   include Devise::Controllers::UrlHelpers
#   default template_path: 'user_notifier_mailer'
#
#   default :from => 'snowbirdhosts@gmail.com'
#
#   def send_shift_reminder_email(address)
#     mail(to: address,
#          subject: "REMINDER: you are scheduled to work at Snowbird tomorrow!")
#   end
#
#   def send_email(address, from, subject, message)
#     mail(to: address, subject: "[#{from}] - #{subject}") do |format|
#       # format.text(content_transfer_encoding: "base64")
#       format.text { render plain: message }
#       format.html { render html: message.html_safe }
#     end
#   end
#
#   def reset_password_instructions(user, token, c)
#
#     @user = user
#     @token = token
#     mail( :to => @user.email,
#           :subject => 'Thanks for signing up for our amazing app' )
#   end
# end

