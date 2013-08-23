Mthost::Application.routes.draw do
  devise_for :users

  resources :users
  resources :mail

  post '/users/save_new', :to => 'users#save_new'

  resources :pages

  match '/show_contact_info', :to => "pages#show_contact_info"


  match '/select_hosts_for_email', :to => "mail#select_hosts_for_email"
  match '/send_custom_mail', :to => "mail#send_custom_mail"
  match '/deliver_mail', :to => "mail#deliver_mail"
  match '/send_mail/:address', :to => "mail#send_mail"

  root :to => "pages#show"

  # catchall route to get pages
  get "/:id" => "pages#show"

end
