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
    @haulers = HostHauler.includes(:riders).all
  end

  def scheduler
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

    unless @selected_hauler.nil?
      @driver = @selected_hauler.driver

      @eligible_riders = @selected_hauler.eligible_riders
      @eligible_drivers = @selected_hauler.eligible_drivers
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

  def set_rider_to_host
    @rider = Rider.includes(:host_hauler).find_by(id: params[:rider_id])
    @hauler = @rider.host_hauler
  end

  def update_rider_in_hauler
    rider = Rider.find_by(id: params[:rider_id])
    hauler = HostHauler.find_by(id: params[:hauler_id])
    host = User.find_by(id: params[:host])

    rider.user_id = host.id
    rider.save

    redirect_to "/hauler_scheduler/#{hauler.id}"  # set hauler_id
  end

  def set_driver_to_host
    @hauler = HostHauler.find_by(id: params[:hauler_id])
  end

  def update_driver_in_hauler
    hauler = HostHauler.find_by(id: params[:hauler_id])
    host = User.find_by(id: params[:host])

    hauler.driver_id = host.id
    hauler.save

    redirect_to "/hauler_scheduler/#{hauler.id}"  # set hauler_id
  end

  def add_hauler
    date_value = Date.parse(params[:date_value])
    @hauler = HostHauler.add_hauler(date_value)
    redirect_to "/hauler_scheduler/#{@hauler.id}?start_date=#{date_value.beginning_of_month}"
  end

  def delete_hauler
    @hauler = HostHauler.find_by(id: params[:hauler_id])
    if @hauler.has_riders?
      flash[:alert] = "Cannot delete hauler that has riders in it"
      redirect_to "/hauler_scheduler/#{@hauler.id}"
    else
      @hauler.destroy
      flash[:notice] = "Hauler Deleted"
      redirect_to "/hauler_scheduler"
    end
  end
end
