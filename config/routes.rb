Rails.application.routes.draw do
  resources :reservations
  resources :locations
  get 'setup/integrate'
  get 'stores/settings'
  match 'stores/settings' => 'stores#save_settings', via: [:post, :patch]


  ########################################################################################
  #   API:
  ########################################################################################
  namespace :api do
    namespace :v1 do
      get 'settings' => 'stores#settings'
      get 'locations' => 'locations#index'
      get 'modal' => 'reservations#modal'
      post 'store_reservations' => 'reservations#create'

      # get 'stores/:public_key/push_event/view/p/:product_id/c/:customer_id.png' => 'stores/product_events#push_view', as: :push_view_event
      # get 'stores/:public_key/push_event/order/p/:product_id/c/:customer_id.png' => 'stores/product_events#push_order'
      # get 'stores/:public_key/push_event/add_to_cart/p/:product_id/c/:customer_id.png' => 'stores/product_events#push_add_to_cart', as: :push_add_to_cart_event
      # get 'stores/:public_key/content/product_page' => 'stores/content#containers'
      # get 'stores/:public_key/content/product_page.html' => 'stores/content#containers'
      # get 'stores/:public_key/content/containers' => 'stores/content#containers'
      #
      # resources :product_events
      #
      # get 'product_counters' => 'product_counters#index'
      # get 'product_counters/:platform_product_id' => 'product_counters#product'
      # get 'product_counters/:platform_product_id/:product_event_type' => 'product_counters#show'
    end
  end

  root :to => 'stores#settings'
  mount ShopifyApp::Engine, at: '/'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
