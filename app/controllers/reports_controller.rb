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
    elsif params[:id] == 'all_host_demographics'
      @report = 'all_host_demographics'
      @title = 'All Host Demographics'
      @hosts = User.all

      respond_to do |format|
        format.csv do
          file = CSV.generate do |csv|
            csv << "Last Name,First Name,Email,Home Phone, Cell Phone".split(',')
            @hosts.each do |user|
              csv << "#{user.name},#{user.email}, #{user.home_phone}, #{user.cell_phone}".split(',')
            end
          end
          render text: file
        end
      end
    elsif params[:id] == 'shifts_by_host'
      @report = 'shifts_by_host'
      @title = "Shift By User Report"
      #@hosts = User.group3.sort {|a, b| a.name <=> b.name} + User.group2.sort {|a, b| a.name <=> b.name} +
      #    User.group1.sort {|a, b| a.name <=> b.name} + User.rookies.sort {|a, b| a.name <=> b.name}
      users = User.includes(:shifts).active_users
      # users.map do |u|
      #   name_array = u.name.split(' ')
      #   u.name = "#{name_array[-1]}, #{name_array[0..-2].join(' ')}"
      # end
      @hosts = users.sort { |a, b| User.sort_value(a) <=> User.sort_value(b) }
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
            csv << "Last Name,First Name,Total On Mountain,Has Holiday,Tours,Ratio,,Comments".split(',')
            @hosts.each do |user|
              csv << "#{user.name},#{user.shifts_for_credit.count},#{user.has_holiday_shift?},#{user.tours.count},#{user.tour_ratio},,#{user.notes}".split(',')
            end
          end
          render text: file
        end
        format.xls
      end
    elsif params[:id] == 'hosts_by_seniority_export'
      @users = User.includes(:shifts).active_users.order(:name).to_a.delete_if { |u| u.supervisor? || u.is_max? }
      @rookies = User.rookies.includes(:roles).order(:name).to_a.delete_if { |u| u.supervisor? || u.is_max? }
      @freshmen =  User.group3.includes(:roles).order(:name).to_a.delete_if { |u| u.team_leader? }.delete_if { |u| u.supervisor? || u.is_max? }
      @junior =  User.group2.includes(:roles).order(:name).to_a.delete_if { |u| u.team_leader? }.delete_if { |u| u.supervisor? || u.is_max? }
      @senior =  User.group1.includes(:roles).order(:name).to_a.delete_if { |u| u.team_leader? }.delete_if { |u| u.supervisor? || u.is_max? }
      @leaders =  User.active_users.order(:name).to_a.delete_if { |u| !u.team_leader? }.delete_if { |u| u.supervisor? || u.is_max? }
      @trainers = User.active_users.order(:name).to_a.delete_if { |u| !u.has_role? :trainer}.delete_if { |u| u.supervisor? || u.is_max? }
      @admin_and_supervisors = User.includes(:shifts).active_users.order(:name).to_a.delete_if { |u| !u.supervisor? && !u.is_max? }
      @drivers = User.active_users.order(:name).to_a.delete_if { |u| !u.driver? }.delete_if { |u| u.supervisor? || u.is_max? }
      respond_to do |format|
        format.csv do
          file = CSV.generate do |csv|
            csv << "GROUP,Number".split(',')
            csv << "Team Leaders,#{@leaders.count}".split(',')
            csv << "Seniors,#{@senior.count}".split(',')
            csv << "Juniors,#{@junior.count}".split(',')
            csv << "Freshmen,#{@freshmen.count}".split(',')
            csv << "Rookies,#{@rookies.count}".split(',')
            csv << "Trainers,#{@trainers.count}".split(',')
            csv << "Drivers,#{@leaders.count}".split(',')
            csv << "Admins,#{@admin_and_supervisors.count}".split(',')
            csv << '------------'.split(',')
            csv << '------------'.split(',')

            csv << "Name,start year,seniority,group".split(',')
            @leaders.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Team Leader".split(',')
            end
            @senior.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Senior".split(',')
            end
            @junior.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Junior".split(',')
            end
            @freshmen.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Freshmen".split(',')
            end
            @rookies.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Rookie".split(',')
            end
            @trainers.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Trainer".split(',')
            end
            @drivers.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Driver".split(',')
            end
            @admin_and_supervisors.each do |u|
              csv << "#{u.name},#{u.snowbird_start_year}, #{u.seniority},Admin/Supervisor".split(',')
            end

          end
          render text: file
        end
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
        @shifts = Shift.includes(:user, :shift_type).order(shift_date: :asc, short_name: :asc)
      else
        report_year = params[:report_year].to_i
        start_year = "#{report_year}-09-01"
        end_year = "#{report_year + 1}-09-01"
        @shifts = Shift.unscoped.includes(:user, :shift_type)
                      .where("shift_date between '#{start_year}' and '#{end_year}'")
                      .order(shift_date: :asc, short_name: :asc)
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
        if u.ongoing_trainings.empty? && !u.rookie?
          @unscheduled_hosts << { name: u.name, id: u.id }
        end
      end

      @prev_year_trainings.uniq!
      @curr_year_trainings.uniq!
      @unscheduled_hosts.uniq!

      @prev_year_trainings.sort!
      @curr_year_trainings.sort!
      @unscheduled_hosts.sort_by! { |h| h[:name] }

      @report = params[:id]
    elsif params[:id] == 'extra_shifts_report'
      @report = 'extra_shifts_report'
      @target_hosts = User.active_users.map do |host|
        if !(host.trainer? ) && (host.shifts_for_analysis.count > 20)
          host
        else
          nil
        end
      end.compact.sort { |a,b| User.sort_value(a) <=> User.sort_value(b) }
    elsif params[:id] == 'shift_inventory_report'
      @report = 'shift_inventory_report'

      @all_counts = Hash.new 0

      Shift.all.map(&:short_name).each {|s| @all_counts[s] += 1 }

      @selected_counts = Hash.new 0
      Shift.where('user_id is not null').map(&:short_name).each {|s| @selected_counts[s] += 1 }
    elsif params[:id] == 'team_leader_shift_report'
      @report = 'team_leader_shift_report'

      @tl_shifts = Shift.where(short_name: 'TL').to_a

      respond_to do |format|
        format.html
        format.csv do
          file = CSV.generate do |csv|
            csv << "Day/Date,Host,ShiftType,Description,Tasks".split(',')
            @tl_shifts.each do |shift|
              csv << "#{shift.day_and_date},#{shift.user.nil? ? "-" : shift.user.name},#{shift.shift_type.short_name},#{shift.shift_type.description},#{shift.shift_type.description},#{shift.shift_type.tasks}".split(',')
            end
          end
          render text: file
        end
        format.xls
      end
    elsif params[:id] == 'system_shift_overview'
      @report = 'system_shift_overview'
      @hosts = User.includes(:shifts).active_users.order(:name).to_a.delete_if { |u| u.supervisor? || u.is_max? }
      @all_shifts = Shift.all.count
      @all_selected_shifts = Shift.where('user_id is not null').count
      @all_unselected_shifts = Shift.where('user_id is null').count

      @hosts_under_20_shifts = []
      @hosts_over_20_shifts = []
      @hosts_less_than_2_tours = []
      @hosts_more_than_7_tours = []
      @hosts_missing_holidays = []

      @hosts.each do |host|
        if host.shifts.count < 20
          @hosts_under_20_shifts << host
        elsif host.shifts.count > 20
          @hosts_over_20_shifts << host
        end
        if host.tours.count > 7
          @hosts_more_than_7_tours << host
        elsif host.tours.count < 2
          @hosts_less_than_2_tours << host
        end

        if !host.has_holiday_shift?
          @hosts_missing_holidays << host
        end
      end
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

  def duties_report
    @title = "Daily Duties Report"
    @start_date = params[:start_date].to_date if params[:start_date]
    @start_date ||= Date.today

    # number of days from start date
    @duration = params[:duration].to_i if params[:duration]
    @duration ||= 7

    @days = get_days_for_duties_report(@start_date, @duration)
  end

  def duties_printable
    @title = "Daily Duties Report"
    @start_date = params[:start_date].to_date if params[:start_date]
    @start_date ||= Date.today

    # number of days from start date
    @duration = params[:duration].to_i if params[:duration]
    @duration ||= 7

    @days = get_days_for_duties_report(@start_date, @duration)

    csv_string = CSV.generate do |csv|
      # data rows
      csv << ["Snowbird Mountain Host Duties Report #{@start_date} for #{@duration} Days"]

      @days.each do |key, shifts|

        csv << ["Duties For:     #{key} #{shifts[0]}"]
        csv << ['Shift Type', 'Host Name', 'Location', 'Time', 'Second Duty']

        shifts[1..-1].each do |s|
          csv << s
        end
        csv << [""]
        csv << [""]
        csv << [""]
      end
    end

    send_data csv_string,
              :type => "text/csv; charset:iso-8859-1;header=present",
             :disposition => "attachment; filename=duties_report#{@start_date.strftime('%a.%Y%m%d')}_#{@duration}.csv"
  end

  def hauler_drivers_report
    # csv_string = CSV.generate do |csv|
    #   # data rows
    #   csv << ["Snowbird Mountain Host Hauler Drivers"]
    #   csv << ['driver name']
    #   User.all.each do |u|
    #     next if !u.driver?
    #
    #     csv << u.name
    #   end
    # end
    #
    # send_data csv_string,
    #           :type => "text/csv; charset:iso-8859-1;header=present",
    #           :disposition => "attachment; filename=host_hauler_drivers.csv"
  end

  private

  def get_days_for_duties_report(start_date, duration)
    shifts = Shift.where("shift_date >= ? AND shift_date < ?", @start_date, @start_date + @duration.days)
         .order(shift_date: :asc, short_name: :asc, updated_at: :asc).to_a
    shift_dates = shifts.map(&:shift_date).uniq.sort
    hash = {}
    shift_dates.each do |sd|
      hash[sd] = []
    end
    shifts.each do |s|
      hash[s.shift_date] << s
    end

    days_hash = {}
    hash.each do |key, value|
      days_hash[key] = []
      days_hash[key] << value.first.day_of_week
      days_hash[key] << get_tl_shift_for_report(value)

      get_a1_shifts_for_report(value).each do |entry|
        days_hash[key] << entry
      end

      get_oc_shifts_for_report(value).each do |entry|
        days_hash[key] << entry
      end

      next
    end

    days_hash
  end

  def get_tl_shift_for_report(value)
    retval = nil
    value.each do |s|
      if s.short_name == 'TL'
        retval = ['TL', s.user.nil? ? 'UNSET' : s.user.name, 'Float', 'All Day', '']
        break
      end
    end
    retval
  end

  def get_a1_shifts_for_report(value)
    retval = []
    a1_count = 0
    is_weekend = value.count >= 15
    value.each do |entry|
      next if entry.short_name != 'A1'

      a1_count += 1
      if entry.user.nil?
        retval << [entry.short_name, 'UNSET',
                   a1_location(a1_count),
                   a1_time(a1_count),
                   '']

      elsif (entry.user.email == COTTER_EMAIL)
        a1_count -= 1
        retval << [entry.short_name, entry.user.name, 'Fill-In', 'All Day', '']
      else
        # populate A1 entries based on order
        retval << [entry.short_name, entry.user.name,
                   a1_location(a1_count),
                   a1_time(a1_count),
                   '']
      end
    end
    retval
  end

  def get_oc_shifts_for_report(value)
    retval = []
    oc_count = 0
    is_weekend = value.count >= 15
    has_cotter = get_cotter_has_a1(value)

    value.each do |entry|
      if entry.short_name == 'OC'

        if has_cotter
          # populate first oc as last a1
          if entry.user.nil?
            retval << [entry.short_name, 'UNSET',
                       a1_location(4),
                       a1_time(4),
                       '']
          else
            retval << [entry.short_name,
                       entry.user.name,
                       a1_location(4),
                       a1_time(4),
                       '']
          end
          has_cotter = false
          next
        end

        oc_count += 1

        if entry.user.nil?
          retval << [entry.short_name, 'UNSET',
                     oc_location(oc_count, is_weekend),
                     oc_time(oc_count, is_weekend),
                     oc_second_duty(oc_count, is_weekend)]
        else
          retval << [entry.short_name,
                     entry.user.name,
                     oc_location(oc_count, is_weekend),
                     oc_time(oc_count, is_weekend),
                     oc_second_duty(oc_count, is_weekend)]
        end
      end


    end
    retval
  end

  def a1_location(cnt)
    case cnt
    when 1..2
      'Gad - Zoom Mask'
    when 3..4
      'Tram Mask'
    else
      'TBD'
    end
  end

  def a1_time(cnt)
    case cnt
    when 1..2
      '8:30 - 2:00'
    when 3..4
      '8:45 - 2:00'
    else
      'TBD'
    end
  end

  def oc_location(cnt, is_weekend)
    case cnt
    when 1
      'Creekside M&G'
    when 2
      'Portico M&G'
    when 3
      if is_weekend
        'Portico M&G'
      else
        'Plasa Deck M&G'
      end
    when 4
      if is_weekend
        'Plaza Deck M&G'
      else
        'Portico PM'
      end
    when 5
      'Plaza PUBS'
    when 6
      'Creekside Lunch'
    when 7
      'Mid-Gad Res'
    when 8
      'Summit Res'
    when 9
      'Portico PM'
    else
      'TBD'
    end
  end

  def oc_time(cnt, is_weekend)
    if is_weekend
      case cnt
      when 1..5
        '8:30 - 10:30'
      when 6..8
        '11:00 - 2:00'
      when 9
        if is_weekend
          '2:00 - 4:30'
        else
          'Plasa Deck M&G'
        end
      else
        'TBD'
      end
    else
      case cnt
      when 1..3
        '8:30 - 10:30'
      when 4
        '2:30 - 4:30'
      when 5
        '8:30 - 10:30'
      else
        'TBD'
      end
    end
  end

  def oc_second_duty(cnt, is_weekend)
    if is_weekend
      case cnt
      when 1
        'Plaza 1:30 - 2:30'
      when 2
        'Plaza 11:30 - 12:30'
      when 3
        'Plaza 12:30 - 1:30'
      when 4
        'Plaza 2:30 - 3:30'
      when 5
        'Plaza 10:30 - 11:30'
      else
        ''
      end
    else
      case cnt
      when 1
        'Plaza 1:30 - 2:30'
      when 2
        'Plaza 11:30 - 12:30'
      when 3
        'Plaza 12:30 - 1:30'
      when 4
        'Plaza 10:30 - 11:30'
      when 5
        'Plaza 2:30 - 3:30'
      else
        ''
      end
    end
  end

  def get_cotter_has_a1(value)
    value.reject { |s| s.user.nil? }
          .reject { |s| s.short_name != 'A1'}
          .map { |s| s.user.email }.uniq.include? COTTER_EMAIL
  end
end
