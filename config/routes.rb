Mthost::Application.routes.draw do
  devise_for :users

  resources :users

  post '/users/save_new', :to => 'users#save_new'

  resources :pages

  match '/show_contact_info', :to => "pages#show_contact_info"
  root :to => "pages#show"

  # catchall route to get pages
  get "/:id" => "pages#show"

end
