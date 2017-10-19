# == Schema Information
#
# Table name: shift_logs
#
#  id           :integer          not null, primary key
#  change_date  :datetime
#  user_id      :integer
#  shift_id     :integer
#  action_taken :string
#  note         :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class ShiftLogsController < ApplicationController
  authorize_resource
  before_action :set_shift_log, only: [:show, :edit, :update, :destroy]

  # GET /shift_logs
  # GET /shift_logs.json
  def index
    if current_user.has_role? :admin
      @shift_logs = ShiftLog.all
    else
      @shift_logs = []
      flash[:alert] = "Access To Logs Denied"
      redirect_to root_path
    end
  end

  # GET /shift_logs/1
  # GET /shift_logs/1.json
  def show
    unless current_user.has_role? :admin
      flash[:alert] = "Access To Logs Denied"
      redirect_to root_path
    end
  end

  # GET /shift_logs/new
  def new
    if current_user.has_role? :admin
      @shift_log = ShiftLog.new
    else
      @shift_log = nil
      flash[:alert] = "Access To Logs Denied"
      redirect_to root_path
    end
  end

  # GET /shift_logs/1/edit
  def edit
    unless current_user.has_role? :admin
      flash[:alert] = "Access To Logs Denied"
      redirect_to root_path
    end
  end

  # POST /shift_logs
  # POST /shift_logs.json
  def create
    if current_user.has_role? :admin
      @shift_log = ShiftLog.new(shift_log_params)

      respond_to do |format|
        if @shift_log.save
          format.html {redirect_to @shift_log, notice: 'Shift log was successfully created.'}
          format.json {render :show, status: :created, location: @shift_log}
        else
          format.html {render :new}
          format.json {render json: @shift_log.errors, status: :unprocessable_entity}
        end
      end
    else
      flash[:alert] = "Access To Logs Denied"
      redirect_to root_path
    end
  end

  # PATCH/PUT /shift_logs/1
  # PATCH/PUT /shift_logs/1.json
  def update
    if current_user.has_role? :admin
      respond_to do |format|
        if @shift_log.update(shift_log_params)
          format.html {redirect_to @shift_log, notice: 'Shift log was successfully updated.'}
          format.json {render :show, status: :ok, location: @shift_log}
        else
          format.html {render :edit}
          format.json {render json: @shift_log.errors, status: :unprocessable_entity}
        end
      end
    else
      flash[:alert] = "Access To Logs Denied"
      redirect_to root_path
    end
  end

  # DELETE /shift_logs/1
  # DELETE /shift_logs/1.json
  def destroy
    if current_user.has_role? :admin
      @shift_log.destroy
      respond_to do |format|
        format.html {redirect_to shift_logs_url, notice: 'Shift log was successfully destroyed.'}
        format.json {head :no_content}
      end
    else
      flash[:alert] = "Access To Logs Denied"
      redirect_to root_path
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_shift_log
    @shift_log = ShiftLog.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def shift_log_params
    params.require(:shift_log).permit(:change_date, :user_id, :shift_id, :action_taken, :note)
  end
end
