Mthost::Application.routes.draw do
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


  get '/download_end_of_year', :to =>  "exports#eoy_download"
  get '/shifts_by_date', :to => 'shifts#shifts_by_date_view'
  get '/skipatrol', :to => "reports#skipatrol"
  get '/skipatrol_printable', :to => "reports#skipatrol_printable"
  get '/shift_print/:id', :to => 'users#shift_print'
  post '/users/save_new', :to => 'users#save_new'
  post '/shifts/assign_team_leaders', :to => 'shifts#assign_team_leaders'
  get '/assign_team_leaders', :to => 'shifts#edit_team_leader_shifts'

  get '/show_contact_info', :to => "pages#show_contact_info"
  get '/select_hosts_for_email', :to => "mail#select_hosts_for_email"
  get '/send_custom_mail', :to => "mail#send_custom_mail"
  get '/deliver_mail', :to => "mail#deliver_mail"
  get '/send_mail/:address', :to => "mail#send_mail"

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

  root :to => "pages#show"

  # catchall route to get pages
  get "/:id" => "pages#show"

end
