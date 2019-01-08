Rails.application.routes.draw do
  root :to => 'stores#settings'
  get 'auth/shopify/callback' => 'callbacks#callback'

  resources :reservations
  resources :locations
  get 'stores/settings'
  get 'stores/help'
  match 'stores/settings' => 'stores#save_settings', via: [:post, :patch]

  namespace :api do
    namespace :v1 do
      get 'modal' => 'reservations#modal'
      post 'store_reservations' => 'reservations#create'
    end
  end

  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
