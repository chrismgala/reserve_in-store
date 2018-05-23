Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.


  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false # Set this to TRUE if you want to see assets as they are in our file system, but it's much faster to leave this as false most of time.

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  ENV['TRUSTED_IPS'].to_s.split(',').each { |ip| BetterErrors::Middleware.allow_ip! ip.strip }
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']

  # Setting this so we can catch emails in mailcatcher
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {address: 'localhost', port: 1025}
end
