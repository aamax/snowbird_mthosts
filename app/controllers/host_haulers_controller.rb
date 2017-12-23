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
    @my_shifts = current_user.shifts.map { |shift| shift.shift_date.strftime("%Y-%m-%d") }
    @start_day = params[:start_date]
    haul_array = HostHauler.all.map { |hauler| [hauler.haul_date, hauler.id] }
    @haulers = {}
    haul_array.each do |haul|
      @haulers[haul[0].to_s] = haul[1]
    end

    if params[:hauler_id]
      @selected_hauler = HostHauler.includes(:riders).find_by(id: params[:hauler_id])
    else
      @selected_hauler = HostHauler.includes(:riders).find_by(haul_date: Date.today)
    end
    @driver = @selected_hauler.driver
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

  def drop_rider
    rider = Rider.find_by(id: params[:rider_id])
    rider.user_id = nil
    rider.save

    redirect_to :back
  end

  def select_rider
    rider = Rider.find_by(id: params[:rider_id])
    rider.user_id = current_user.id
    rider.save

    redirect_to :back
  end
end
