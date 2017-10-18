# == Schema Information
#
# Table name: shifts
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  shift_type_id   :integer          not null
#  shift_status_id :integer          default(1), not null
#  shift_date      :date
#  day_of_week     :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  short_name      :string
#

class ShiftsController < ApplicationController
  require "json"
  authorize_resource
  load_resource :except => [:index]

  respond_to :html, :json, :js

  def index
    @days = DAYNAMES.map{|u| ["#{u}", "#{u[0...3]}"]}
    @shift_types = ShiftType.uniq.pluck(:short_name).to_a.sort {|a,b| a <=> b }
        # ShiftType.all.map {|st| st.short_name[0..1] }.uniq.sort {|a,b| a <=> b }
    @users = User.active_users.pluck(:name).sort #map{|u| ["#{u.name}"]}.sort
    per_page = SysConfig.first.shift_count
    per_page ||= 80

    @return_params = {"start_from_today" => true, "show_shifts_expanded" => false, "show_only_unselected" => false,
                      "show_only_holidays" => false, "include_meeting_shifts" => false,
                      "show_only_shifts_i_can_pick" => !current_user.has_role?(:admin),
                      "shift_types_to_show" => "", 'days_of_week_to_show' => {},
                      "hosts_to_show" => {}, "date_set_to_show" => '',
                      "date_for_calendar" => Date.today.strftime("%Y-%m-%d")
    }

    unless params['filter'].nil?
      form_filters = params['filter']
    end
    form_filters ||= {"start_from_today" => '1',
                          "shifts_i_can_pick" => current_user.has_role?(:admin) ? '0' : '1',
                          'shifttype' => "", 'dayofweek' => {}, "hosts" => {},
                          "date" => '', "date_for_calendar" => Date.today.strftime("%Y-%m-%d")

    }

    @shifts = Shift.get_shifts_for_index(current_user, @return_params, form_filters,
                  current_user.has_role?(:admin)).paginate(:page => params[:page], :per_page => per_page)
    @shifts
  end

  def destroy
    if !Shift.destroy(params[:id])
      flash[:alert] = "Error destroying shift."
      log_shift_destroy(params[:id], "failed", current_user)
    else
      log_shift_destroy(params[:id], "success", current_user)
    end
    redirect_to :back
  end

  def drop_shift
    s = Shift.find(params[:id])
    log_shift_dropped(s, current_user)
    s.user_id = nil
    s.save

    redirect_to :back
  end

  def select_shift
    s = Shift.find(params[:id])
    if s.user_id.nil?
      s.user_id = current_user.id
      s.save
      log_shift_selected(s, current_user)
    else
      redirect_to "/shifts", :alert => "Sorry - this shift has already been taken. Please try a different shift"
      return
    end

    redirect_to :back
  end

  def edit
    if ((@shift.user_id == current_user.id) || (current_user.has_role? :admin)  || @shift.user_id.nil?)
      @title = "Edit Shift"
      @shift.user_id.nil? ? @user_name = "UnSet" : @user_name = @shift.user.name
      @userlist = User.active_users
      if (current_user.has_role? :admin)
          if @shift.meeting?
            # trim all users who are in a meeting on this day out of list
            shift_users = Shift.where("shift_date = ? and shift_type_id = ?", @shift.shift_date, @shift.shift_type_id).map { |s| s.user}
          else
            # trim all users who are working already (non meeting) for that day out of list
            shift_users = Shift.where("shift_date = ? and short_name not like 'M%'", @shift.shift_date).map { |s| s.user}
          end

          @userlist = @userlist - shift_users
          @userlist.sort! { |a,b| a.name <=> b.name }
      else
        @userlist = [current_user]
      end
    else
      redirect_to shifts_path
    end
  end

  def update
    previous_user_id = @shift.user_id
    if @shift.update_attributes(params[:shift])
      flash[:success] = "Shift updated."
      log_shift_update(previous_user_id, @shift, current_user)
      redirect_to shifts_path #+ "?" + strParams
      return
    else
      @title = "Edit Shift"
      flash[:failure] = "ERROR: shift not updated. #{@shift.errors.messages}"
      log_shift_failed_update(@shift, params[:shift], current_user)
      render 'edit'
      return
    end

    # TODO add code to preserve params for shifts index filter
    #@params = {:filter=>params[:shift][:filter]}.to_param unless params[:shift].nil?
    #@params ||= {:filter=>params[:filter]}.to_param
    #
    #params[:shift].delete(:filter) unless params[:shift].nil?
    #
    #strParams = ""
    #if !params[:page].blank?
    #  strParams = "page=" + params[:page]
    #  unless @params.blank?
    #    strParams += "&"
    #  end
    #end
    #strParams += @params
    #
    #if (params[:status].blank?)
    #  # update from edit form
    #  if ((@shift.user_id == current_user.id) || (current_user.has_role? :admin) ||
    #      (@shift.user_id.nil?))
    #    if @shift.update_attributes(params[:shift])
    #      flash[:success] = "Shift updated."
    #
    #      redirect_to shifts_path + "?" + strParams
    #      return
    #    else
    #      @title = "Edit Shift"
    #      flash[:failure] = "ERROR: shift not updated."
    #      render 'edit'
    #      return
    #    end
    #  else
    #    redirect_to shifts_path + "?" + strParams
    #    return
    #  end
    #else
    #  if (params[:status] == "clear")
    #    # clear shift
    #    clear_shift_host(@shift.id)
    #    flash[:success] = "Shift Cleared..."
    #  elsif (params[:status] == "select")
    #    # make sure i can still select this shift
    #    unless can_i_pick_this_shift(current_user, @shift)
    #      flash[:failure] = "You do not have permissions to select this shift."
    #    else
    #      # select shift
    #      select_shift_host(@shift.id, current_user.id)
    #      flash[:success] = "Shift Selected..."
    #    end
    #  elsif (params[:status] == "Worked")
    #    # to worked 1
    #    update_shift_status(@shift.id, 1)
    #    flash[:success] = "Shift Status Set To Worked..."
    #  elsif (params[:status] == "Missed")
    #    # to missed -1
    #    update_shift_status(@shift.id, -1)
    #  end
    #
    #  redirect_to shifts_path + "?" + strParams
    #end
  end

  def delete_shifts
    Shift.delete_all
    redirect_to :back, :notice => "All Shifts Have Been Deleted"
  end

  def shifts_by_date_view
    if params[:date] == ""
      params[:date] = nil
    end

    if params[:date]
      @datevalue = params[:date].to_date
      @shifts = Shift.where("shift_date = ?", @datevalue)

      #if @datevalue >= HostSite::season_start
      #  @shifts = Shift.where("shift_date = ?", params[:date])
      #else
      #  @shifts = Shift.unscoped.where("shift_date = ?", params[:date])
      #end

      #elsif params[:filter][:date]
      #@shifts = Shift.where("shift_date = ?" params[:filter][:date])

    elsif !params[:filter]
      @datevalue = Date.today

      @shifts = []
    end
  end

  def edit_team_leader_shifts
    @leaders = User.with_role(:team_leader).to_a.delete_if {|u| !u.active_user}
    render 'edit_team_leader_shifts'
  end

  def assign_team_leaders
    Shift.assign_team_leaders(params)
    redirect_to shifts_path # TODO just show TL shifts
  end

  private
  def log_shift_destroy(shift_id, result_msg, user)
    ShiftLog.create(change_date: DateTime.now, user_id: user.id,
                  shift_id: shift_id, action_taken: "Delete Shift", note: result_msg)
  end

  def log_shift_dropped(shift, user_dropping)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    ShiftLog.create(change_date: DateTime.now, user_id: user_dropping.id,
                    shift_id: shift.id, action_taken: "Dropped Shift",
                    note: "#{user_dropping.name} DROPPED shift #{shift_str} for user: #{shift.user.name}")
  end

  def log_shift_selected(shift, user_selecting)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    ShiftLog.create(change_date: DateTime.now, user_id: user_selecting.id,
                    shift_id: shift.id, action_taken: "Selected Shift",
                    note: "#{user_selecting.name} SELECTED shift #{shift_str} for user: #{shift.user.name}")
  end

  def log_shift_update(previous_user_id, shift, user)
    prev_user = User.find(previous_user_id)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    ShiftLog.create(change_date: DateTime.now, user_id: user.id,
                    shift_id: shift.id, action_taken: "Updated Shift",
                    note: "#{user.name} UPDATED shift #{shift_str} set from: #{prev_user.name} to user: #{shift.user.name}")
  end

  def log_shift_failed_update(shift, shift_hash, user)
    shift_str = "#{shift.id}:#{shift.short_name}:#{shift.shift_date}"
    ShiftLog.create(change_date: DateTime.now, user_id: user.id,
                shift_id: shift_id, action_taken: "Failed Updating Shift",
                note: "#{user.name} FAILED TO UPDATE shift #{shift_str} set from: #{prev_user.name} with hash: #{shift_hash.inspect}")
  end
end
