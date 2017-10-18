json.extract! shift_log, :id, :change_date, :user_id, :shift_id, :action_taken, :note, :created_at, :updated_at
json.url shift_log_url(shift_log, format: :json)