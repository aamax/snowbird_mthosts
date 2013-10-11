class ReportsController < ApplicationController

  respond_to :html

  def show
    if params[:id] == 'confirmations'
      @report = 'confirmations'
      unless current_user.has_role? :admin
        redirect_to root_path, flash[:alert] = 'Access not allowed.'
      else
        @non_confirmed = User.where(confirmed: false, :active_user => true).sort {|a,b| a.name <=> b.name }
        @confirmed = User.where(confirmed: true, :active_user => true).sort {|a,b| a.name <=> b.name }
      end
    elsif params[:id] == 'shifts_by_host'
      @report = 'shifts_by_host'
      @title = "Shift By User Report"
      @hosts = User.group3.sort {|a, b| a.name <=> b.name} + User.group2.sort {|a, b| a.name <=> b.name} +
          User.group1.sort {|a, b| a.name <=> b.name} + User.rookies.sort {|a, b| a.name <=> b.name}

      @total_shifts = Shift.all
      @total_assigned_shifts = Shift.assigned
      @total_open_shifts = Shift.un_assigned
    end
  end

end
