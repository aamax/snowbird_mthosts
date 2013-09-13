class ShiftCollectionsController < ApplicationController
  def index
    current_date = params[:date].to_date unless params[:date].nil?
    current_date ||= Date.today

    @days_of_week = []
    Date::DAYNAMES.each_with_index {|m, i| @days_of_week << [m, i]}

    @shift_types = ShiftType.all
    @selected_shifts = nil # TODO get shifts for selected day if it's set...
  end

  def update
    selected_shifts = params[:day][:selected_shifts]
    selected_dates = params[:selected_dates]
    replace_old = params[:option] == "0"

    err_list = []

    selected_dates.each do |date|
      if replace_old
        # delete any shifts on this day
        Shift.delete_all("shift_date = '#{date}'")
      end

      selected_shifts.each do |shift|
        attr = {}
        attr[:shift_type_id] = shift
        attr[:shift_status_id] = 0
        attr[:shift_date] = date

        @newshift = Shift.new(attr)

        if !@newshift.save
          err_list << "Error creating shift: #{shift} on #{date}"
        end

      end
    end

    if err_list.length == 0
      flash[:success] = "New Shift Created"
    else
      flash[:alert] = err_list.inspect;
      return
    end

    redirect_to shifts_path
  end
end
