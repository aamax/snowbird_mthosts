require 'csv'

class ReportsController < ApplicationController

  respond_to :html

  def show
    @seniority = ['Group1 (Senior)', 'Group2 (Middle)', 'Group3 (Newer)', 'Rookie' ]
    if params[:id] == 'confirmations'
      @report = 'confirmations'
      unless current_user.has_role? :admin
        redirect_to root_path, flash[:alert] = 'Access not allowed.'
      else
        @non_confirmed = User.where(confirmed: false, :active_user => true).sort {|a,b| a.name <=> b.name }
        @confirmed = User.where(confirmed: true, :active_user => true).sort {|a,b| a.name <=> b.name }
      end
    elsif params[:id] == 'phone_list'
      @report = 'phone_list'
      @title = "Mt Host Phone and Address List - Season Starting in #{HostConfig.season_year}"

      @user_list = User.active_users.sort {|a, b| a.last_name <=> b.last_name }

      # show page or export csv is format is .csv
      respond_to do |format|
        format.html
        format.csv do

          file = CSV.generate do |csv|
            csv << "Last Name,First Name,Mobile,Home,Mailing,Email,is Rookie?".split(',')
            @user_list.each do |user|
              csv << [user.first_name,user.last_name,user.cell_phone,user.home_phone,user.address,user.email,user.rookie? ? "YES" : ""]
            end
          end
          render text: file
        end
        format.xls
      end
    elsif params[:id] == 'shifts_by_host'
      @report = 'shifts_by_host'
      @title = "Shift By User Report"
      #@hosts = User.group3.sort {|a, b| a.name <=> b.name} + User.group2.sort {|a, b| a.name <=> b.name} +
      #    User.group1.sort {|a, b| a.name <=> b.name} + User.rookies.sort {|a, b| a.name <=> b.name}
      users = User.includes(:shifts).active_users
      users.map do |u|
        name_array = u.name.split(' ')
        u.name = "#{name_array[-1]}, #{name_array[0..-2].join(' ')}"
      end
      @hosts = users.sort { |a, b| a.name <=> b.name }
      @hosts.delete_if {|h| h.email == COTTER_EMAIL }

      if params['filter'] && (params['filter']['Seniority'] || params['filter']['team_leaders'])
        filters = params['filter']['Seniority'].reject {|e| e.empty?}
        if filters.count > 0
          if (!filters.include? @seniority[0])
            # filter out senior hosts
            @hosts = @hosts.delete_if {|h| h.group_1? }
          end
          if !filters.include? @seniority[1]
            # filter out middle
            @hosts = @hosts.delete_if {|h| h.group_2? }
          end
          if !filters.include? @seniority[2]
            # filter out newer
            @hosts = @hosts.delete_if {|h| h.group_3? }
          end
          if !filters.include? @seniority[3]
            # filter out rookies
            @hosts = @hosts.delete_if {|h| h.rookie? }
          end
        else
          keep_leaders = params['filter']['team_leaders'] == '1'
          if keep_leaders == true
            @hosts = @hosts.delete_if {|h| !h.team_leader? }
          end
        end
      end
      if params['filter'] && params['filter']['need_shifts']== '1'
        tmp_arr = Array.new(@hosts)
        @hosts = []
        tmp_arr.each do |user|
          if user.rookie?
            @hosts << user if user.shifts.count < 16
          else
            @hosts << user if user.shifts.count < 18
          end
        end
      end

      @total_shifts = Shift.all
      @total_assigned_shifts = Shift.assigned
      @total_open_shifts = Shift.un_assigned

      respond_to do |format|
        format.html
        format.csv do
          file = CSV.generate do |csv|
            csv << "Last Name,First Name,Total On Mountain,Tours,Ratio,,Comments".split(',')
            @hosts.each do |user|
              csv << "#{user.name},#{user.shifts_for_credit.count},#{user.tours.count},#{user.tour_ratio},,#{user.notes}".split(',')
            end
          end
          render text: file
        end
        format.xls
      end
    elsif params[:id] == 'shift_summary'
      @report = 'shift_summary'
      allshifts = Shift.unscoped.order(shift_date: :asc, short_name: :asc)
      first_year = allshifts.first.shift_date.year
      last_year = allshifts.last.shift_date.year
      @years = []
      (first_year..last_year - 1).each do |yr|
        @years << yr
      end
      report_year = @years.last
      if params[:report_year].nil?
        @shifts = Shift.includes(:user, :shift_type).order(:shift_date)
      else
        report_year = params[:report_year].to_i
        start_year = "#{report_year}-09-01"
        end_year = "#{report_year + 1}-09-01"
        @shifts = Shift.unscoped.includes(:user, :shift_type).where("shift_date between '#{start_year}' and '#{end_year}'").order(:shift_date)
      end
      @report_year = report_year
    elsif params[:id] == 'shift_log_review'
      @logs = ShiftLog.all.order(created_at: :desc)
      @report = 'shift_log_review'
    elsif params[:id] == 'ongoing_training_report'
      @prev_year_trainings = []
      OngoingTraining.all.includes(:training_date).each do |training|
        if (training.shift_date.strftime('%Y-%m-%d') == OGOMT_FAKE_DATE) && !training.user_id.nil?
          @prev_year_trainings << training.user.name
        end
      end

      @curr_year_trainings = []
      OngoingTraining.all.includes(:training_date).includes(:user).each do |training|
        if (training.shift_date.strftime('%Y-%m-%d') != OGOMT_FAKE_DATE) && (!training.user_id.nil?)
          @curr_year_trainings << training.user.name
        end
      end

      @unscheduled_hosts = []
      User.active_users.includes(:ongoing_trainings).each do |u|
        if u.ongoing_trainings.empty?
          @unscheduled_hosts << u.name
        end
      end

      @prev_year_trainings.uniq!
      @curr_year_trainings.uniq!
      @unscheduled_hosts.uniq!

      # TODO sort all arrays by host name and/or shift date ******** <<<<<<<

      @report = params[:id]
    elsif params[:id] == 'extra_shifts_report'
      @report = 'extra_shifts_report'

    end
  end

  def skipatrol
    @title = "Ski Patrol Daily Report"
    @date = params[:date].to_date if params[:date]
    @date ||= Date.today
    @day1 = Shift.where("shift_date = ?", @date).order("short_name")
    @day2 = Shift.where("shift_date = ?", @date + 1.day).order("short_name")
    @day3 = Shift.where("shift_date = ?", @date + 2.day).order("short_name")
    @day4 = Shift.where("shift_date = ?", @date + 3.day).order("short_name")
    @day5 = Shift.where("shift_date = ?", @date + 4.day).order("short_name")
    @day6 = Shift.where("shift_date = ?", @date + 5.day).order("short_name")
    @day7 = Shift.where("shift_date = ?", @date + 6.day).order("short_name")
  end

  def skipatrol_printable
    @title = "Ski Patrol Daily Report"
    @date = params[:date].to_date if params[:date]
    @date ||= Date.today

    @day1 = Shift.where("shift_date = ?", @date).order("short_name")
    @day2 = Shift.where("shift_date = ?", @date + 1.day).order("short_name")
    @day3 = Shift.where("shift_date = ?", @date + 2.day).order("short_name")
    @day4 = Shift.where("shift_date = ?", @date + 3.day).order("short_name")
    @day5 = Shift.where("shift_date = ?", @date + 4.day).order("short_name")
    @day6 = Shift.where("shift_date = ?", @date + 5.day).order("short_name")
    @day7 = Shift.where("shift_date = ?", @date + 6.day).order("short_name")

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
