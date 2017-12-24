Mthost::Application.routes.draw do
  resources :shift_logs
  devise_for :users

  resources :users
  resources :mail
  resources :shift_types
  resources :shifts
  resources :shift_collections
  resources :galleries
  resources :exports
  resources :sys_configs
  resources :reports
  resources :pages
  resources :host_haulers, only: [:index]

  get '/download_end_of_year', :to =>  "exports#eoy_download"
  get '/export/shift_summary/:year', :to =>  "exports#shift_summary_download"
  get '/hosts_by_seniority', :to => 'users#hosts_by_seniority'
  get '/hosts_by_roles', :to => 'users#hosts_by_roles'
  get '/shifts_by_date', :to => 'shifts#shifts_by_date_view'
  get '/skipatrol', :to => "reports#skipatrol"
  post '/skipatrol', :to => "reports#skipatrol"
  get '/skipatrol_printable', :to => "reports#skipatrol_printable"
  get '/shift_print/:id', :to => 'users#shift_print'
  post '/users/save_new', :to => 'users#save_new'
  post '/shifts/assign_team_leaders', :to => 'shifts#assign_team_leaders'
  get '/assign_team_leaders', :to => 'shifts#edit_team_leader_shifts'

  get '/show_contact_info', :to => "pages#show_contact_info"
  get '/select_hosts_for_email', :to => "mail#select_hosts_for_email"
  get '/send_custom_mail', :to => "mail#send_custom_mail"
  post '/send_custom_mail', :to => "mail#send_custom_mail"
  post '/deliver_mail', :to => "mail#deliver_mail"
  get '/send_mail/:address', :to => "mail#send_mail"
  get '/send_mail/hauler/:hauler_id', :to => 'mail#send_hauler_mail'

  get '/set_start_year/:year', :to => "users#set_start_year"
  get '/clear_assignments', :to => "users#clear_assignments"
  get '/delete_shifts', :to => "shifts#delete_shifts"
  get '/reset_confirms_and_passwords', :to => "users#reset_confirms_and_passwords"
  get '/init_confirmations', :to => "users#init_confirmations"
  get '/init_meetings', :to => "users#init_meetings"


  post '/set_user_active/:value', :to => "users#set_user_active"

  get '/drop_shift/:id', :to => 'shifts#drop_shift'
  get '/select_shift/:id', :to => 'shifts#select_shift'

  get '/ghost_user/:id', :to => 'users#ghost_user'
  get '/un_ghost_user', :to => 'users#un_ghost_user'

  get "shift_logs/by_shift/:shift_id", :to => 'shift_logs#by_shift'
  get "shift_logs/by_user/:user_id", :to => 'shift_logs#by_user'


  get '/hauler_scheduler/:hauler_id', :to => 'host_haulers#scheduler'

  get '/drop_driver/:id', :to => 'host_haulers#drop_driver'
  get '/select_driver/:id', :to => 'host_haulers#select_driver'

  get '/drop_rider/:rider_id', :to => 'host_haulers#drop_rider'
  get '/select_rider/:rider_id', :to => 'host_haulers#select_rider'
  get '/export_hauler/:hauler_id', :to =>  "exports#host_hauler_download"
  get '/set_rider_to_host/:rider_id', :to => 'host_haulers#set_rider_to_host'
  post '/update_rider_in_hauler', :to => 'host_haulers#update_rider_in_hauler'
  get '/set_driver_to_host/:hauler_id', :to => 'host_haulers#set_driver_to_host'
  post '/update_driver_in_hauler', :to => 'host_haulers#update_driver_in_hauler'
  get '/add_hauler/:date_value', :to => 'host_haulers#add_hauler'
  get '/hauler_scheduler', :to => 'host_haulers#scheduler'


  # catchall route to get pages
  get "/:id" => "pages#show"
  root :to => "pages#show"
end
