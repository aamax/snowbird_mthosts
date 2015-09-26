class UsersController < ApplicationController
  require "json"

  respond_to :html, :json, :js
  load_and_authorize_resource

  def get_survey_users
    users = User.active_users
    users.map do |u|
      name_array = u.name.split(' ')
      u.name = "#{name_array[-1]}, #{name_array[0..-2].join(' ')}"
    end
    @hosts = users.sort { |a, b| a.name <=> b.name }.map { |u| {name: u.name, id: u.id}}
    respond_with @hosts
  end

  def index
    if current_user.has_role? :admin
      @inactive_users = User.includes(:shifts).inactive_users
    end
    @users = User.includes(:shifts).active_users
    @users = @users.sort {|a,b| a.name <=> b.name }
  end

  def hosts_by_seniority
    @users = User.includes(:shifts).active_users
    @rookies = User.rookies
    @freshmen = User.group3
    @junior = User.group2
    @senior = User.group1
    @leaders = User.includes(:shifts).active_users.to_a.delete_if {|u| !u.team_leader? }
    @missing = @users - (@rookies + @freshmen + @junior + @senior + @leaders)
  end

  def show

  end

  def edit
  end

  def new
    @user.start_year = HostConfig.season_year
    @user.active_user = true
  end

  def destroy
    if User.destroy(params[:id])
      redirect_to users_path, notice: "User deleted"
    else
      redirect_to users_path, alert: "Unable to Delete User: #{@user.errors.messages}"
    end
  end

  def update
    is_conf_page =  (params[:user][:page_type] == 'confirmation_page')
    if is_conf_page && params[:user][:password].blank? && !(current_user.has_role? :admin)
      redirect_to :back, :alert => "You must set your password when confirming your information"
    else
      params[:user].except!(:page_type)
      if params[:user][:password].blank?
        params[:user].except!(:password)
        params[:user].except!(:password_confirmation)
      end
      if !@user.update_attributes(params[:user])
        redirect_to :back, :alert => "Error saving user: #{@user.errors.messages}"
      else
        process_user_roles params

        if is_conf_page
          sign_in(@user, bypass: true)
          redirect_to root_path
        else
          redirect_to users_path
        end
      end
    end
  end

  def create
    @user = User.create(params[:user])
    if @user.id.nil?
      flash[:alert] = "Error creating new User: #{@user.errors.messages}"
      redirect_to new_user_path
    else
      process_user_roles params
      redirect_to users_path
    end
  end

  def ghost_user
    session[:admin_user_id] = current_user.id
    usr = User.find(params[:id])
    sign_in(usr, bypass: true)
    session[:ghost_user] = usr.id
    redirect_to root_path
  end

  def un_ghost_user
    unless session[:admin_user_id].nil?
      user = User.find(session[:admin_user_id])
      sign_in(user, bypass: true)
      session[:admin_user_id] = nil
      session[:ghost_user] = nil
    else
      session[:admin_user_id] = nil
      session[:ghost_user] = nil
    end
    redirect_to root_path
  end

  def set_user_active
    arr = params['value'].split(',')

    user = User.find_by_id(arr[0])
    user.active_user = arr[1] == 'true'
    user.save
    render :json => {
        user: user
    }
  end

  def shift_print
    @user = User.find(params[:id])
  end

  def set_start_year
    if params[:year].nil?
      redirect_to :back, :alert => 'Error - no year set'
    else
      User.all.each do |u|
        u.start_year = params[:year]
        u.save
      end

      redirect_to :back, :notice => "All users set to start year of: #{params[:year]}"
    end
  end

  def clear_assignments
    Shift.all.each do |s|
      s.user_id = nil
      s.save
    end
    redirect_to :back, :notice => "All Shift Assignments Have Been Cleared"
  end

  def reset_confirms_and_passwords
    User.active_users.each do |u|
      u.confirmed = false
      u.password = 'password'
      u.save
    end
    redirect_to :back, :notice => "All Users Have Been Reset..."
  end

  def init_confirmations
    User.active_users.each do |u|
      u.confirmed = false
      u.save
    end
    redirect_to :back, :notice => "All User Confirmations Have Been Reset..."
  end

  def init_meetings
    User.populate_meetings
    redirect_to :back, :notice => "All Meetings have been processed."
  end

  private
  def process_user_roles params
    return if !current_user.has_role? :admin
    if params['role'].nil?
      @user.roles = []
    else
      missing_roles = []
      extra_roles = []
      params['role'].each do |k, v|
        if !(@user.roles.map { |r| r.name }.include? k)
          missing_roles << k
        end
      end
      @user.roles.each do |r|
        if params['role'][r.name].nil?
          extra_roles << r.name
        end
      end
      extra_roles.each do |r|
        @user.remove_role r
      end
      missing_roles.each do |r|
        @user.add_role r
      end
    end
  end

end
