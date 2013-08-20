json.array!(@users) do |user|
  json.id           user.id
  json.name         user.name
  json.email        user.user.email
  json.street       user.street
  json.city         user.city
  json.state        user.state
  json.zip          user.zip
  json.home_phone   user.home_phone
  json.cell_phone   user.cell_phone
  json.alt_email    user.alt_email
  json.start_year   user.start_year
  json.notes        user.notes
  json.confirmed    user.confirmed
  json.nickname     user.nickname
  json.is_current_user user.is_current_user
  json.is_admin     user.has_role? :admin
  json.roles        user.roles
end