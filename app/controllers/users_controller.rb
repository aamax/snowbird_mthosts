class UsersController < ApplicationController
  require "json"

  load_and_authorize_resource
  respond_to :html, :json, :js

  def index
    gon.current_user = current_user

    @users.each do |u|
      if u.id == current_user.id
        u['is_current_user'] = true
      else
        u['is_current_user'] = false
      end

      u['is_admin'] = u.has_role? :admin
      u['roles'] = u.roles
      u['seniority'] = u.seniority
      u['shifts'] = u.shifts
    end
    object = respond_to do |format|
      format.html
      format.json  {render json: @users}
    end
    object
  end

  def show
    gon.current_user = current_user
    gon.user_to_show = @user
    @user['is_admin'] = @user.has_role? :admin
    @user['roles'] = @user.roles

    object = respond_to do |format|
      format.html
      format.json  {render json: @user}
    end
    object
  end

  def destroy
    if User.destroy(params[:id])
      #redirect_to datasets_path, notice: "Dataset deleted"
    else
      #redirect_to datasets_path, alert: "Unable to delete Dataset"
      #flash[:alert] = "Unable to Delete User"
    end
    respond_with @user
  end

  def update
    user_params = setUserParamsForUpdate(params)
    if user_params[:password].blank?
      user_params.except!(:password)
      user_params.except!(:password_confirmation)
    end
    if !@user.update_attributes(user_params)
      flash[:alert] = "Error saving user: #{@user.errors.messages}"
    end

    object = respond_to do |format|
      format.html { redirect_to :back }
      format.json  {render json: @user}
    end
    object
  end

  def save_new
    user_params = setUserParamsForUpdate(params)
    @user = User.create(user_params)
    respond_with @user
  end

  def create
    user_params = setUserParamsForUpdate(params)
    @user = User.create(user_params)
    respond_with @user
  end

  private

  def setUserParamsForUpdate(params)
    retval = params[:user]
    unless params[:email].nil?
      retval = {name: params[:name], email: params[:email], street: params[:street], city: params[:city],
                state: params[:state], zip: params[:zip], home_phone: params[:home_phone], cell_phone: params[:cell_phone],
                alt_email: params[:alt_email], start_year: params[:start_year], notes: params[:notes],
                confirmed: params[:confirmed], active_user: params[:active_user], nickname: params[:nickname]}
      if params[:password]
        retval[:password] = params[:password]
      end
    end
    retval
  end
end
