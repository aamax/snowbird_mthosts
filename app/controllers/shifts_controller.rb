class ShiftsController < ApplicationController
  require "json"

  load_and_authorize_resource
  respond_to :html, :json, :js

  def index
    @shifts = Shift.paginate(:page => params[:page], :per_page => 75)
  end

  def destroy
    Shift.destroy(params[:id])
    redirect_to :back
  end

  def edit
    @shift = Shift.find(params[:id])
    if ((@shift.user_id == current_user.id) || (current_user.has_role? :admin)  || @shift.user_id.nil?)
      @title = "Edit Shift"
      @shift.user_id.nil? ? @user_name = "UnSet" : @user_name = @shift.user.name

      if !@shift.shift_type_id.nil?
        @aShiftType = @shift.shift_type
        @ShiftTypeSN = @aShiftType.short_name[0...2]
        @ShiftTypeD = @aShiftType.description
        @ShiftTypeST = @aShiftType.start_time
        @ShiftTypeET = @aShiftType.end_time
        @ShiftTypeSC = @aShiftType.tasks
        @ShiftTypeDT = @shift.shift_date
      else
        @ShiftTypeSN = "UnSet"
        @ShiftTypeD = "UnSet"
        @ShiftTypeST = "UnSet"
        @ShiftTypeET = "UnSet"
        @ShiftTypeSC = "UnSet"
        @ShiftTypeDT = "UnSet"
      end

      if (current_user.has_role? :admin)
        if @ShiftTypeDT != "UnSet"
          @userlist = User.all

          shiftlist = Shift.where("shift_date = ?", @shift.shift_date)
          shiftlist.each do |ashift|
            @userlist.delete(ashift.user) if ashift.user != @shift.user
          end
        else
          @userlist = all
        end
      else
        @userlist = [current_user]
      end
      @userlist.sort! { |a,b| a.name <=> b.name }
    else
      redirect_to shifts_path
    end
  end

  def update
    @shift = Shift.find(params[:id])

    @params = {:filter=>params[:shift][:filter]}.to_param unless params[:shift].nil?
    @params ||= {:filter=>params[:filter]}.to_param

    params[:shift].delete(:filter) unless params[:shift].nil?

    strParams = ""
    if !params[:page].blank?
      strParams = "page=" + params[:page]
      unless @params.blank?
        strParams += "&"
      end
    end
    strParams += @params

    if (params[:status].blank?)
      # update from edit form
      if ((@shift.user_id == current_user.id) || (current_user.admin?) ||
          (@shift.user_id.nil?))
        if @shift.update_attributes(params[:shift])
          flash[:success] = "Shift updated."

          current_user.update_shift_by_current_user(@shift)

          redirect_to shifts_path + "?" + strParams
          return
        else
          @title = "Edit Shift"
          flash[:failure] = "ERROR: shift not updated."
          render 'edit'
          return
        end
      else
        redirect_to shifts_path + "?" + strParams
        return
      end
    else
      if (params[:status] == "clear")
        # clear shift
        clear_shift_host(@shift.id)
        flash[:success] = "Shift Cleared..."
      elsif (params[:status] == "select")
        # make sure i can still select this shift
        unless can_i_pick_this_shift(current_user, @shift)
          flash[:failure] = "You do not have permissions to select this shift."
        else
          # select shift
          select_shift_host(@shift.id, current_user.id)
          flash[:success] = "Shift Selected..."
        end
      elsif (params[:status] == "Worked")
        # to worked 1
        update_shift_status(@shift.id, 1)
        flash[:success] = "Shift Status Set To Worked..."
      elsif (params[:status] == "Missed")
        # to missed -1
        update_shift_status(@shift.id, -1)
        flash[:success] = "Shift Status Set To Missed..."
      end

      redirect_to shifts_path + "?" + strParams
    end
  end


  #def show
  #  respond_with @shift
  #end
  #
  #
  #
  #def create
  #  s_params = setShiftParamsForUpdate(params)
  #  @shift = Shift.create(s_params)
  #  respond_with @shift
  #end

  def drop_shift
    s = Shift.find(params[:id])
    s.user_id = nil
    s.save
    redirect_to :back
  end

  def select_shift
    s = Shift.find(params[:id])
    s.user_id = current_user.id
    s.save
    redirect_to :back
  end

  #private
  #def setShiftParamsForUpdate(params)
  #  retval = {user_id: params['user_id'], shift_type_id: params['shift_type_id'],
  #            shift_status_id: params['shift_status_id'], shift_date: params['shift_date']}
  #  retval
  #end
  #
end
