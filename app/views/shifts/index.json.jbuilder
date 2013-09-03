json.array!(@shifts) do |s|
  json.user_id                s.user.id
  json.user_name              s.user.name
  json.shift_type_id          s.shift_type.id
  json.shift_type_short_name  s.shift_type.short_name
  json.shift_type_description s.shift_type.description
  json.status           s.status_string
  json.shift_date             s.shift_date
  json.day_of_week            s.day_of_week
end