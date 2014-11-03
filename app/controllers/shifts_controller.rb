class ShiftsController < ApplicationController
  require "json"
  authorize_resource
  load_resource :except => [:index]


  respond_to :html, :json, :js

  def index
    @days = DAYNAMES.map{|u| ["#{u}", "#{u[0...3]}"]}
    @shift_types = ShiftType.all.map {|st| st.short_name[0..1] }.uniq.sort {|a,b| a <=> b }
    @users = User.active_users.map{|u| ["#{u.name}"]}.sort
    per_page = 80

    @sts = @usrs = ''
    @dow = {}
    @show_expanded = @holidays = @unselected = false
    @from_today = @can_select = true
    @dt = Date.today.strftime('%Y-%m-%d')
    @date = ''

    if current_user.has_role? :admin
      @can_select = false
    end

    if params['filter']
      @show_expanded = params['filter']['show_expanded'] == '1'

      @sts = params['filter']['shifttype']
      @dow = params['filter']['dayofweek'].reject{ |e| e.empty? }
      @dt = params['filter']['date']
      @date = @dt
      @usrs = params['filter']['host'].reject{ |e| e.empty? }
      @from_today = (params['filter']['start_from_today'] == '1')
      @can_select = (params['filter']['shifts_i_can_pick'] == '1')
      @holidays = (params['filter']['holiday_shifts'] == '1')
      @unselected = (params['filter']['show_unselected'] == '1')
      if @can_select == false
        @shifts = Shift.from_today(@from_today).by_shift_type(@sts).by_date(@dt).by_day_of_week(@dow).by_users(@usrs).by_holidays(@holidays).by_unselected(@unselected).paginate(:page => params[:page], :per_page => per_page)
      else
        @shifts = Shift.from_today(@from_today).by_shift_type(@sts).by_date(@dt).by_day_of_week(@dow).by_holidays(@holidays).by_users(@usrs).by_unselected(true).delete_if {|s| s.can_select(current_user) == false }.paginate(:page => params[:page], :per_page => per_page)
      end
    elsif current_user.has_role? :admin
      @can_select = false
      @shifts = Shift.from_today(true).paginate(:page => params[:page], :per_page => per_page)
    else
      @can_select = true
      @shifts = Shift.from_today(true).delete_if {|s| s.can_select(current_user) == false }.paginate(:page => params[:page], :per_page => per_page)
    end
  end

  def destroy
    if !Shift.destroy(params[:id])
      flash[:alert] = "Error destroying shift."
    end
    redirect_to :back
  end

  def drop_shift
    s = Shift.find(params[:id])
    s.user_id = nil
    s.save
    redirect_to :back
  end

  def select_shift
    s = Shift.find(params[:id])
    if s.user_id.nil?
      s.user_id = current_user.id
      s.save
    else
      redirect_to :shifts_path, :alert => "Sorry - this shift has already been taken. Please try a different shift"
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
          shift_users = Shift.where("shift_date = ?", @shift.shift_date).map { |s| s.user}
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
    if @shift.update_attributes(params[:shift])
      flash[:success] = "Shift updated."

      redirect_to shifts_path #+ "?" + strParams
      return
    else
      @title = "Edit Shift"
      flash[:failure] = "ERROR: shift not updated."
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
    @leaders = User.with_role(:team_leader).delete_if {|u| !u.active_user}
    render 'edit_team_leader_shifts'
  end

  def assign_team_leaders
    Shift.assign_team_leaders(params)
    redirect_to shifts_path # TODO just show TL shifts
  end
end
