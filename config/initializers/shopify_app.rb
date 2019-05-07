ShopifyApp.configure do |config|
  config.application_name = 'In-Store Reserver'
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY'].presence || ENV['SHOPIFY_API_KEY'].presence
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET'].presence || ENV['SHOPIFY_API_SECRET'].presence
  config.scope = 'read_products, read_themes, write_themes, read_script_tags, write_script_tags, read_locations, read_inventory, read_locations, read_orders, write_orders, read_draft_orders, write_draft_orders, read_product_listings, read_content, write_content, read_checkouts, write_checkouts, read_analytics, read_customers, write_customers' # read_customers,write_customers
  config.embedded_app = true
  config.after_authenticate_job = false
  config.session_repository = Store
  config.webhooks = [
      {topic: 'app/uninstalled', address: "#{ENV['BASE_APP_URL']}/webhooks/app_uninstalled", format: 'json'},
  ]
end
