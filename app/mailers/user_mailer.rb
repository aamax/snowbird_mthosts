class UserMailer < ActionMailer::Base
  default from: "snowbirdhosts@gmail.com"

  def send_email(toaddress, fromaddress, subject, message)
    @user = toaddress
    mail( :to => toaddress,
          :from => fromaddress,
          :reply_to => fromaddress,
          :subject => subject,
          :body => message)
  end
end
