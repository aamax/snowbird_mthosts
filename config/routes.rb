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


  match '/download_end_of_year', :to =>  "exports#eoy_download"
  get '/shift_print/:id', :to => 'users#shift_print'
  post '/users/save_new', :to => 'users#save_new'

  resources :pages
  match '/show_contact_info', :to => "pages#show_contact_info"
  match '/select_hosts_for_email', :to => "mail#select_hosts_for_email"
  match '/send_custom_mail', :to => "mail#send_custom_mail"
  match '/deliver_mail', :to => "mail#deliver_mail"
  match '/send_mail/:address', :to => "mail#send_mail"

  get '/drop_shift/:id', :to => 'shifts#drop_shift'
  get '/select_shift/:id', :to => 'shifts#select_shift'

  match "/gallery_page", :to => "galleries#gallery_page"

  root :to => "pages#show"

  # catchall route to get pages
  get "/:id" => "pages#show"

end
