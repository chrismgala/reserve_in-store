Rails.application.routes.draw do
  root :to => 'stores#settings'
  get 'auth/shopify/callback' => 'callbacks#callback'

  resources :reservations
  resources :locations
  get 'stores/settings'
  get 'stores/help'
  get 'stores/templates'
  get 'stores/iframe_preview'
  match 'stores/settings' => 'stores#save_settings', via: [:post, :patch]

  namespace :api do
    namespace :v1 do
      get 'locations/modal' => 'locations#modal'
      get 'locations' => 'locations#index'
      get 'reservations/modal' => 'reservations#modal'
      get 'inventory' => 'inventory#index'
      post 'reservations' => 'reservations#create'

      # Legacy endpoints
      post 'store_reservations' => 'reservations#create'
      get 'modal' => 'reservations#modal'
    end
  end

  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
