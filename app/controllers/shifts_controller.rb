class ShiftsController < ApplicationController
  require "json"

  load_and_authorize_resource
  respond_to :html, :json, :js

  def index
    aUser = current_user
    gon.current_user = aUser
    gon.current_is_admin = current_user.has_role? :admin

    object = respond_to do |format|
      format.html
      format.json  {render json: @shifts}
    end
    object
  end

  def show
    object = respond_to do |format|
      format.html
      format.json  {render json: @shift}
    end
    object
  end

  def destroy
    ShiftType.destroy(params[:id])
    respond_with @shift
  end

  def update
    s_params = setShiftTypeParamsForUpdate(params)
    @shift.update_attributes(s_params)
    respond_with @shift
  end

  def create
    s_params = setShiftParamsForUpdate(params)
    # TODO update with Shift Model structure
    @shift = Shift.create(short_name: params['short_name'], description: params['description'],
                                   start_time: params['start_time'], end_time: params['end_time'],
                                   tasks: params['tasks'])
    respond_with @shift
  end

  private
  # TODO update with Shift Model structure
  def setShiftParamsForUpdate(params)
    retval = {short_name: params[:short_name], description: params[:description], start_time: params[:start_time],
              end_time: params[:end_time], tasks: params[:tasks]}
    retval
  end
end
