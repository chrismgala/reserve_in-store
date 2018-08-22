Rails.application.routes.draw do
  resources :reservations
  resources :locations
  get 'stores/settings'
  match 'stores/settings' => 'stores#save_settings', via: [:post, :patch]

  namespace :api do
    namespace :v1 do
      get 'modal' => 'reservations#modal'
      post 'store_reservations' => 'reservations#create'
    end
  end

  root :to => 'stores#settings'
  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
