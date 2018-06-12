Rails.application.routes.draw do
  resources :reservations
  resources :locations
  get 'setup/integrate'
  get 'stores/settings'
  match 'stores/settings' => 'stores#save_settings', via: [:post, :patch]
  root :to => 'stores#settings'
  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
