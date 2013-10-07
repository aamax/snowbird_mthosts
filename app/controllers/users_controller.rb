class UsersController < ApplicationController
  load_and_authorize_resource

  def index
    if current_user.has_role :admin
      @inactive_users = User.inactive_users
    end
    @users = User.active_users
    @users.sort! {|a,b| a.name <=> b.name }

    @users.each do |u|
      add_meetings_to_shifts(u)
    end
  end

  def show
    add_meetings_to_shifts(@user)
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
      redirect_to datasets_path, alert: "Unable to Delete User: #{@user.errors.messages}"
    end
  end

  def update
    if params[:user][:password].blank?
      params[:user].except!(:password)
      params[:user].except!(:password_confirmation)
    end
    if !@user.update_attributes(params[:user])
      redirect_to :back, :alert => "Error saving user: #{@user.errors.messages}"
    else
      redirect_to users_path
    end
  end

  def create
    @user = User.create(params[:user])
    if @user.id.nil?
      flash[:alert] = "Error creating new User: #{@user.errors.messages}"
      redirect_to new_user_path
    else
      redirect_to users_path
    end
  end

  def shift_print
    @user = User.find(params[:id])
    add_meetings_to_shifts(@user)
  end

  private

  def add_meetings_to_shifts(u)
    mtgs = u.get_meetings
    u.working_shifts = u.shifts
    u.working_shifts << mtgs if (mtgs.length > 0)
    u.working_shifts = u.working_shifts.flatten.sort {|a,b| a.shift_date <=> b.shift_date }
  end
end
