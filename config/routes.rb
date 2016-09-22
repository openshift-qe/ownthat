Rails.application.routes.draw do
  get 'welcome/index'
  root 'welcome#index'

  resources :locks
  match '/locks/by_values(.:format)' => 'locks#update', via: [:put, :patch], as: "update_by_values"
  # put   '/locks/by_values(.:format)' => 'locks#update'

  post '/locks/from_pool(.:format)' => 'locks#lock_from_pool', as: "create_from_pool"

  resources :pools

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
