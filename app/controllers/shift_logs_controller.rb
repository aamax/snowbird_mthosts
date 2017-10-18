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
  before_action :set_shift_log, only: [:show, :edit, :update, :destroy]

  # GET /shift_logs
  # GET /shift_logs.json
  def index
    @shift_logs = ShiftLog.all
  end

  # GET /shift_logs/1
  # GET /shift_logs/1.json
  def show
  end

  # GET /shift_logs/new
  def new
    @shift_log = ShiftLog.new
  end

  # GET /shift_logs/1/edit
  def edit
  end

  # POST /shift_logs
  # POST /shift_logs.json
  def create
    @shift_log = ShiftLog.new(shift_log_params)

    respond_to do |format|
      if @shift_log.save
        format.html { redirect_to @shift_log, notice: 'Shift log was successfully created.' }
        format.json { render :show, status: :created, location: @shift_log }
      else
        format.html { render :new }
        format.json { render json: @shift_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shift_logs/1
  # PATCH/PUT /shift_logs/1.json
  def update
    respond_to do |format|
      if @shift_log.update(shift_log_params)
        format.html { redirect_to @shift_log, notice: 'Shift log was successfully updated.' }
        format.json { render :show, status: :ok, location: @shift_log }
      else
        format.html { render :edit }
        format.json { render json: @shift_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shift_logs/1
  # DELETE /shift_logs/1.json
  def destroy
    @shift_log.destroy
    respond_to do |format|
      format.html { redirect_to shift_logs_url, notice: 'Shift log was successfully destroyed.' }
      format.json { head :no_content }
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
