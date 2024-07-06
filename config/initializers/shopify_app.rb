ShopifyApp.configure do |config|
  config.application_name = 'Reserve In-store'
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY'].presence || ENV['SHOPIFY_API_KEY'].presence
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET'].presence || ENV['SHOPIFY_API_SECRET'].presence
  config.api_version = '2024-04'
  config.scope = 'read_products, read_orders, read_themes, write_themes, read_script_tags, write_script_tags, read_locations, read_inventory, read_product_listings' # read_customers,write_customers
  config.embedded_app = true
  #config.after_authenticate_job = false
  config.after_authenticate_job = { job: AppInstalledJob }
  config.shop_session_repository = Store
  config.allow_jwt_authentication = true
  config.webhooks = [
      {topic: 'app/uninstalled', address: "#{ENV['BASE_APP_URL']}/webhooks/app_uninstalled", format: 'json'},
      {topic: 'inventory_levels/update', address: "#{ENV['BASE_APP_URL']}/webhooks/inventory_levels_update", format: 'json'},
      {topic: 'locations/create', address: "#{ENV['BASE_APP_URL']}/webhooks/locations_create", format: 'json'},
      {topic: 'locations/update', address: "#{ENV['BASE_APP_URL']}/webhooks/locations_update", format: 'json'},
      {topic: 'locations/delete', address: "#{ENV['BASE_APP_URL']}/webhooks/locations_delete", format: 'json'},
      {topic: 'products/create', address: "#{ENV['BASE_APP_URL']}/webhooks/products_create", format: 'json'},
      {topic: 'products/update', address: "#{ENV['BASE_APP_URL']}/webhooks/products_update", format: 'json'},
      {topic: 'shop/update', address: "#{ENV['BASE_APP_URL']}/webhooks/shop_update", format: 'json'},
      {topic: 'orders/create', address: "#{ENV['BASE_APP_URL']}/webhooks/orders_create", format: 'json'},
  ]
  config.scripttags = [
    {event:'onload', src: "#{ENV['PUBLIC_CDN_BASE_PATH'].chomp('/')}/reserveinstore.js"}
  ]
end

# ShopifyApp::Utils.fetch_known_api_versions                        # Uncomment to fetch known api versions from shopify servers on boot
# ShopifyAPI::ApiVersion.version_lookup_mode = :raise_on_unknown    # Uncomment to raise an error if attempting to use an api version that was not previously known
