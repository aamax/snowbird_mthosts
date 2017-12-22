# == Schema Information
#
# Table name: host_haulers
#
#  id         :integer          not null, primary key
#  driver_id  :integer
#  haul_date  :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class HostHaulersController < ApplicationController
  before_filter :authenticate_user!
  load_and_authorize_resource

  def index
    @working_date = Date.today.strftime("%Y-%m-%d")
    @working_date_value = Date.today

    @riders = []
    @driver = nil
    @selected_hauler = nil
    @haulers = {}

    start_day = @working_date_value.beginning_of_month - 10.days
    end_day = @working_date_value.end_of_month + 10.days
    HostHauler.includes(:riders).where(haul_date: start_day..end_day).each do |hh|
      @haulers[hh.haul_date.to_s] = hh
      if hh.haul_date.strftime("%Y-%m-%d") == @working_date
        @driver = hh.driver
        @selected_hauler = hh
      end
    end
  end

  def drop_driver
    hh = HostHauler.find(params[:id])
    hh.driver_id = nil
    hh.save

    redirect_to :back
  end

  def select_driver
    hh = HostHauler.find(params[:id])
    hh.driver_id = current_user.id
    hh.save

    redirect_to :back
  end

  # def edit
  # end

  def show
    @dt = params[:id]
  end

  # def update
  # end
  #
  # def new
  # end
  #
  # def create
  # end
  #
  # def destroy
  # end

  def get_host_hauler_schedule
    # pass in param for date, return json for driver and all riders

  end
end
