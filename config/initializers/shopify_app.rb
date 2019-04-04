ShopifyApp.configure do |config|
  config.application_name = 'In-Store Reserver'
  config.api_key = ENV['SHOPIFY_CLIENT_API_KEY']
  config.secret = ENV['SHOPIFY_CLIENT_API_SECRET']
  config.scope = 'read_products, read_themes, write_themes, read_script_tags, write_script_tags' # read_customers,write_customers
  config.embedded_app = true
  config.after_authenticate_job = false
  config.session_repository = Store
  config.webhooks = [
      {topic: 'app/uninstalled', address: "#{ENV['BASE_APP_URL']}/webhooks/app_uninstalled", format: 'json'},
  ]
end
