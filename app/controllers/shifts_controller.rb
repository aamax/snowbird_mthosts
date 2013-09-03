class ShiftsController < ApplicationController
  require "json"

  load_and_authorize_resource
  respond_to :html, :json, :js

  def index
    aUser = current_user
    gon.current_user = aUser
    gon.current_is_admin = current_user.has_role? :admin

    respond_with @shifts
  end

  def show
    respond_with @shift
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
    @shift = Shift.create(s_params)
    respond_with @shift
  end

  private
  def setShiftParamsForUpdate(params)
    retval = {user_id: params['user_id'], shift_type_id: params['shift_type_id'],
              shift_status_id: params['shift_status_id'], shift_date: params['shift_date']}
    retval
  end
end
