source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.3.3'

gem 'ace-rails-ap', '~> 4.1.4' # For making HTML editors look pretty
gem 'bootsnap', '>= 1.1.0', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'dotenv-rails', '~> 2.4.0' # Adds the `ENV['BLEH']` ability to access environment variables
gem 'jbuilder', '~> 2.5' # Build JSON APIs with ease, not really being used.
gem 'jquery-rails', '~> 4.3', '>= 4.3.3' # Use jquery as the JavaScript library
gem 'kaminari', '~> 1.1', '>= 1.1.1' # Pagination such as `Product.all.page(params[:page])`
gem 'non-stupid-digest-assets', '~> 1.0.9' # used for compiling both digest and non-digest assets in production
gem 'pg', '~> 0.20.0' # Use postgresql as the database for Active Record
gem 'puma', '~> 3.11' # Use Puma as the app server
gem 'rack-cors', require: 'rack/cors' # used for Cross-Origin Resource Sharing (CORS) serve public assets
gem 'rails', '~> 5.2.0' # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'sass-rails', '~> 5.0' # Use SCSS for stylesheets
gem 'sentry-raven', '~> 2.7.4' # For bug tracking
gem 'shopify_api', '~> 4.11.0'
gem 'shopify_app', '~> 8.2.6' # Shopify Application Rails engine and generator
gem 'turbolinks', '~> 5' # Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'uglifier', '>= 1.3.0' # Use Uglifier as codampressor for JavaScript assets

group :production do
  gem 'sendgrid-ruby', '~> 5.2.0' # For sending email in production only
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'selenium-webdriver'
  # Easy installation and use of chromedriver to run system tests with Chrome
  gem 'chromedriver-helper'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

