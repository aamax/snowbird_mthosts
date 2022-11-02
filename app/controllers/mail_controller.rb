class MailController < ApplicationController

  def send_shift_reminder_email
    emailaddress = 'aamaxworks@gmail.com'

    UserNotifierMailer.send_shift_reminder_email(emailaddress).deliver
    redirect_to root_path, :notice => "Email Sent to #{emailaddress}"
  end

  # select hosts form
  def select_hosts_for_email
    if current_user.has_role? :admin
      inactive_users = User.inactive_users
    else
      inactive_users = []
    end
    @users = User.active_users + inactive_users
    @users.sort! {|a,b| a.name <=> b.name }

    @title = "Select Hosts For Email Message"
  end

  def send_custom_mail
    @emailaddress = params[:recipients].map {|k, v|
      if k != "0"
        [k, v]
      end
    }.delete_if { |v| v[1] == "0"}.map { |m| User.find(m[0]).email }.join(",")
    @title = params[:title]
    @fromaddress = current_user.email

    render :send_mail
  end

  def deliver_mail
    @useremail = params[:mailmessage][:toaddress]
    @subject = params[:mailmessage][:subject]
    @fromaddress = current_user.email if current_user #params[:mailmessage][:fromaddress]
    @fromaddress ||= params[:mailmessage][:fromaddress]
    @message = "Reply To: [#{current_user.name}(#{current_user.email})]<hr/><p>#{params[:mailmessage][:message]}</p>"

    UserNotifierMailer.send_email(@useremail, @fromaddress, @subject, @message).deliver

    flash[:notice] = "Email sent to #{@useremail}..."
    redirect_to(root_path)
  end

  def send_mail
    if params[:address]
      @emailaddress = params[:format].nil? ? params[:address] : "#{params[:address]}.#{params[:format]}"

      @title = "Create Email Message"
      current_user ? @fromaddress = current_user.email : @fromaddress = ""

      if !@emailaddress.include?("@")
        # handle special email lists etc.
        @emailaddress = get_multiple_email_addresses

        if @emailaddress.nil?
          redirect_to root_path, :notice => "unable to address email."
        end
      end
    else
      @emailaddress = get_addresses_from_checkboxes
      @title = "Create Email Message"
      if current_user
        @fromaddress = current_user.email
      else
        @fromaddress = ""
      end
    end
  end

  def send_hauler_mail
    render :send_mail
  end

  private
  def get_addresses_from_checkboxes
    iusers = []

    params[:recipients].each do |key, value|
      if value == "1"
        iusers << key
      end
    end

    destaddresses = ""
    iusers.each do |userid|
      auser = User.find(userid)

      if !@emailaddress.blank?
        @emailaddress = @emailaddress + "," + auser.email
      else
        @emailaddress = auser.email
      end
    end
    @emailaddress
  end

  def get_multiple_email_addresses
    case @emailaddress
      when 'ADMINUSERS'
        users = User.with_role(:admin)
      when 'TEAMLEADER'
        users = User.active_users.with_role(:team_leader)
      when 'ROOKIES'
        users = User.rookies
       when 'SURVEYORS'
        users = User.active_users.with_role(:surveyor)
      when 'DRIVERS'
        users = User.active_users.with_role(:driver)
      when 'GROUP1'
        users = User.group1
      when 'GROUP2'
        users = User.group2
       when 'GROUP3'
        users = User.group3
      when 'ALLACTIVEHOSTS'
        users = User.active_users
      when 'ALLHOSTS'
        users = User.all
      when 'ALLINACTIVEHOSTS'
        users = User.inactive_users
      when 'NONCONFIRMED'
        users = User.non_confirmed_users
      when 'THIS_DATE'
        users = Shift.where(shift_date: params[:date]).map {|s| s.user }
    # when 'OGOMT_THIS_DATE'
    #   # assumes there is only one training date per params[:date]...  TODO: revisit this when refactoring for future use
    #     users = TrainingDate.where(shift_date: params[:date]).map { |t| t.ongoing_trainings }.first.map { |u| u.user }
    when 'hauler'
        hauler = HostHauler.find_by(id: params[:id])
        users = hauler.riders.map {|r| r.user.nil? ? nil : r.user }.compact
        users << hauler.driver
      else
        @emailaddress = nil
    end
    if (users.nil? || users == [])
      @emailaddress = nil
    else
      users = users.uniq
      @emailaddress = users.compact.map {|u| u.email}.join(',')
    end

    @emailaddress
  end

end
