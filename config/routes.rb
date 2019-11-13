Rails.application.routes.draw do
  root :to => 'stores#settings'
  get 'auth/shopify/callback' => 'callbacks#callback'

  resources :reservations
  resources :locations
  resources :users
  get 'stores/settings'
  get 'stores/activate'
  get 'stores/reinstall'
  get 'stores/resync'
  get 'stores/deactivate'
  get 'stores/setup'
  get 'stores/help'
  get 'stores/templates'
  get 'stores/iframe_preview'
  match 'stores/settings' => 'stores#save_settings', via: [:post, :patch]

  get 'shopify/recurring_application_charge/create' => 'shopify/recurring_application_charge#create', as: :subscribe
  get 'shopify/recurring_application_charge/callback' => 'shopify/recurring_application_charge#callback', as: :recurring_application_charge_callback

  namespace :api do
    namespace :v1 do
      get 'locations/modal' => 'locations#modal'
      match 'locations/modal' => 'locations#modal', via: [:post, :get]

      get 'locations' => 'locations#index'
      match 'reservations/modal' => 'reservations#modal', via: [:post, :get]
      get 'inventory' => 'inventory#index'
      get 'inventories' => 'inventory#index_multi'
      post 'reservations' => 'reservations#create'
      get 'reservations' => 'reservations#index'

      # Legacy endpoints
      post 'store_reservations' => 'reservations#create'
      get 'modal' => 'reservations#modal'
    end
  end

  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
