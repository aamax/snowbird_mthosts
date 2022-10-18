class UserNotifierMailer < ApplicationMailer
  default :from => 'snowbirdhosts@gmail.com'

  # send a signup email to the user, pass in the user object that   contains the user's email address
  def send_signup_email(address)

    mail( :to => address,
          :subject => 'Thanks for signing up for our amazing app' )
  end
end
