require 'csv'

class ReportsController < ApplicationController

  respond_to :html

  def show
    @seniority = ['Group1 (Senior)', 'Group2 (Middle)', 'Group3 (Newer)', 'Rookie', 'Team Leaders' ]
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
      if params['filter'] && params['filter']['Seniority']
        filters = params['filter']['Seniority'].reject {|e| e.empty?}
        if filters.count > 0
          if (!filters.include? @seniority[0])
            # filter out senior hosts
            @hosts = @hosts.delete_if {|h| h.group_1_only? }
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
          if !filters.include? @seniority[4]
            @hosts = @hosts.delete_if {|h| h.team_leader? }
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

      @seniority = ['Group1 (Senior)', 'Group2 (Middle)', 'Group3 (Newer)', 'Rookie', 'Team Leaders' ]

      respond_to do |format|
        format.html
        format.csv do

          file = CSV.generate do |csv|
            csv << "Last Name,First Name,Total,Worked,Pending,Missed,Comments".split(',')
            @hosts.each do |user|
              csv << "#{user.name},#{user.shifts.count},#{user.shifts_worked.count},#{user.pending_shifts.count},#{user.missed_shifts.count},#{user.notes}".split(',')
            end
          end
          render text: file
        end
        format.xls
      end
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
