class ShiftsController < ApplicationController
  require "json"

  load_and_authorize_resource
  respond_to :html, :json, :js

  def index
    @shifts = Shift.paginate(:page => params[:page], :per_page => 75)
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
    s.user_id = current_user.id
    s.save
    redirect_to :back
  end

  def edit
    if ((@shift.user_id == current_user.id) || (current_user.has_role? :admin)  || @shift.user_id.nil?)
      @title = "Edit Shift"
      @shift.user_id.nil? ? @user_name = "UnSet" : @user_name = @shift.user.name
      @userlist = User.all
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
    #    flash[:success] = "Shift Status Set To Missed..."
    #  end
    #
    #  redirect_to shifts_path + "?" + strParams
    #end
  end

end
