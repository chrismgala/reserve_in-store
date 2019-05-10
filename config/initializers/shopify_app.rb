ShopifyApp.configure do |config|
  config.application_name = 'Reserve In-store'
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY'].presence || ENV['SHOPIFY_API_KEY'].presence
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET'].presence || ENV['SHOPIFY_API_SECRET'].presence
  config.scope = 'read_products, read_themes, write_themes, read_script_tags, write_script_tags, read_locations, read_inventory, read_locations, read_orders, write_orders, read_draft_orders, write_draft_orders, read_product_listings, read_content, write_content, read_checkouts, write_checkouts, read_analytics, read_customers, write_customers' # read_customers,write_customers
  config.embedded_app = true
  config.after_authenticate_job = { job: "AppInstalledJob" }
  config.session_repository = Store
  config.webhooks = [
      {topic: 'app/uninstalled', address: "#{ENV['BASE_APP_URL']}/webhooks/app_uninstalled", format: 'json'},
      {topic: 'inventory_levels/update', address: "#{ENV['BASE_APP_URL']}/webhooks/inventory_levels_update", format: 'json'},
      {topic: 'locations/create', address: "#{ENV['BASE_APP_URL']}/webhooks/locations_create", format: 'json'},
      {topic: 'locations/update', address: "#{ENV['BASE_APP_URL']}/webhooks/locations_update", format: 'json'},
      {topic: 'locations/delete', address: "#{ENV['BASE_APP_URL']}/webhooks/locations_delete", format: 'json'},
      {topic: 'products/create', address: "#{ENV['BASE_APP_URL']}/webhooks/products_create", format: 'json'},
      {topic: 'products/update', address: "#{ENV['BASE_APP_URL']}/webhooks/products_update", format: 'json'},
      {topic: 'shop/update', address: "#{ENV['BASE_APP_URL']}/webhooks/shop_update", format: 'json'},
  ]
  config.scripttags = [
    {event:'onload', src: "#{ENV['CDN_JS_BASE_PATH']}reserveinstore.js"}
  ]
end
