class UserMailer < ActionMailer::Base
  default from: "snowbirdmthosts@gmail.com"

  def send_email(current_user, toaddress, fromaddress, subject, message)
    if !current_user.nil? && !current_user.has_role?(:admin)
      dest = toaddress.split(',').delete_if do |u|
        usr = User.find_by_email(u)
        usr.nil? || !usr.active_user?
      end
      toaddress = dest.join(',')
    end

    @user = toaddress
    mail( :bcc => toaddress,
          :from => fromaddress,
          :reply_to => fromaddress,
          :subject => subject,
          :body => message)
  end

  def send_daily_email(toaddress, fromaddress, subject, message)
    # puts "\nPARAMS:\nto: #{toaddress}\nfrom: #{fromaddress}\nsubj: #{subject}\nmsg: #{message}\n\n"
    @user = toaddress
    mail( :bcc => toaddress,
          :from => fromaddress,
          :reply_to => fromaddress,
          :subject => subject,
          :body => message)
  end

end
