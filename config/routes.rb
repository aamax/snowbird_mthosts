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
  resources :surveys

  match '/export_surveys_to_csv', :to => "surveys#export_to_csv"
  match '/get_survey_users', :to => "users#get_survey_users"
  match '/get_user_surveys', :to => 'users#get_user_surveys'

  match '/download_end_of_year', :to =>  "exports#eoy_download"
  match '/shifts_by_date', :to => 'shifts#shifts_by_date_view'
  match '/skipatrol', :to => "reports#skipatrol"
  match '/skipatrol_printable', :to => "reports#skipatrol_printable"
  get '/shift_print/:id', :to => 'users#shift_print'
  post '/users/save_new', :to => 'users#save_new'

  resources :pages
  match '/show_contact_info', :to => "pages#show_contact_info"
  match '/select_hosts_for_email', :to => "mail#select_hosts_for_email"
  match '/send_custom_mail', :to => "mail#send_custom_mail"
  match '/deliver_mail', :to => "mail#deliver_mail"
  match '/send_mail/:address', :to => "mail#send_mail"

  match '/set_start_year/:year', :to => "users#set_start_year"
  match '/clear_assignments', :to => "users#clear_assignments"
  match '/delete_shifts', :to => "shifts#delete_shifts"
  match '/reset_confirms_and_passwords', :to => "users#reset_confirms_and_passwords"
  match '/init_confirmations', :to => "users#init_confirmations"

  post '/set_user_active/:value', :to => "users#set_user_active"

  get '/drop_shift/:id', :to => 'shifts#drop_shift'
  get '/select_shift/:id', :to => 'shifts#select_shift'

  match "/gallery_page", :to => "galleries#gallery_page"

  get '/ghost_user/:id', :to => 'users#ghost_user'
  get '/un_ghost_user', :to => 'users#un_ghost_user'

  root :to => "pages#show"

  # catchall route to get pages
  get "/:id" => "pages#show"

end
