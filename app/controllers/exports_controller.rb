require 'csv'

class ExportsController < ApplicationController
  def eoy_download
    shifts = Shift.all.order(shift_date: :asc, shift_type_id: :asc)
    currentdt = ""

    csv_string = CSV.generate do |csv|
      # header row
      csv << ["host", "day", "date", "shifttype", "description", "tasks", "status"]

      # data rows
      shifts.each do |obj|
        if currentdt != obj.shift_date
          csv << ['----------------','----------------','----------------','----------------','----------------','----------------','----------------']
        end
        currentdt = obj.shift_date
        status_value = (obj.shift_status_id == -1) ? "missed" : "worked"
        name = obj.user.nil? ? "UnSet" : obj.user.name
        csv << [name, obj.day_of_week, obj.shift_date.strftime('%Y-%m-%d'), obj.shift_type.short_name[0..1], obj.shift_type.description,
                obj.shift_type.tasks, status_value]
      end
    end

    send_data csv_string,
              :type => "text/csv; charset:iso-8859-1;header=present",
              :disposition => "attachment; filename=EOY_shift_report#{Date.today.strftime('%Y%m%d')}.csv"

  end
end
