require 'csv'

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

  def skipatrol
    @title = "Ski Patrol Daily Report"
    @date = params[:date].to_date if params[:date]
    @date ||= Date.today
    @day1 = Shift.where("shift_date = ?", @date)
    @day2 = Shift.where("shift_date = ?", @date + 1.day)
    @day3 = Shift.where("shift_date = ?", @date + 2.day)
    @day4 = Shift.where("shift_date = ?", @date + 3.day)
    @day5 = Shift.where("shift_date = ?", @date + 4.day)
    @day6 = Shift.where("shift_date = ?", @date + 5.day)
    @day7 = Shift.where("shift_date = ?", @date + 6.day)
  end

  def skipatrol_printable
    @title = "Ski Patrol Daily Report"
    @date = params[:date].to_date if params[:date]
    @date ||= Date.today

    @day1 = Shift.where("shift_date = ?", @date)
    @day2 = Shift.where("shift_date = ?", @date + 1.day)
    @day3 = Shift.where("shift_date = ?", @date + 2.day)
    @day4 = Shift.where("shift_date = ?", @date + 3.day)
    @day5 = Shift.where("shift_date = ?", @date + 4.day)
    @day6 = Shift.where("shift_date = ?", @date + 5.day)
    @day7 = Shift.where("shift_date = ?", @date + 6.day)

    days = [@day1, @day2, @day3, @day4, @day5, @day6, @day7]

    csv_string = CSV.generate do |csv|
      # header row


      # data rows
      days.each_with_index do |day, i|
        csv << ["Snowbird Mountain Host Staffing For:     #{(@date + i.day).strftime('%a.   %Y-%m-%d')}"]
        csv << [""]

        csv << ["Host", "Shift", "Description", "Tasks"]
        day.each do |objs|
          name = objs.user.name unless objs.nil? || objs.user.nil?
          name ||= "Unset"

          csv << [name, objs.short_name, objs.shift_type.description,
                  objs.shift_type.tasks]
        end
        csv <<[""]
        csv << [""]
      end
    end

    send_data csv_string,
              :type => "text/csv; charset:iso-8859-1;header=present",
              :disposition => "attachment; filename=ski_patrol_report#{@date.strftime('%a.%Y%m%d')}.csv"
  end


end
