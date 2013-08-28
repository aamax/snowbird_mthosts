class ShiftTypesController < ApplicationController
  require "json"

  load_and_authorize_resource
  respond_to :html, :json, :js

  def index
    aUser = current_user
    gon.current_user = aUser
    gon.current_is_admin = current_user.has_role? :admin

    object = respond_to do |format|
      format.html
      format.json  {render json: @shift_types}
    end
    object
  end

  def show
    object = respond_to do |format|
      format.html
      format.json  {render json: @shift_type}
    end
    object
  end

  def destroy
    ShiftType.destroy(params[:id])
    respond_with @shift_type
  end

  def update
    st_params = setShiftTypeParamsForUpdate(params)
    @shift_type.update_attributes(st_params)
    respond_with @shift_type
  end

  def create
    st_params = setShiftTypeParamsForUpdate(params)
    @shift_type = ShiftType.create(short_name: params['short_name'], description: params['description'],
                                   start_time: params['start_time'], end_time: params['end_time'],
                                   tasks: params['tasks'])
    respond_with @shift_type
  end

  private

  def setShiftTypeParamsForUpdate(params)
    retval = {short_name: params[:short_name], description: params[:description], start_time: params[:start_time],
              end_time: params[:end_time], tasks: params[:tasks]}
    retval
  end
end
