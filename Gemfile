source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.3.3'


gem 'rails', '~> 5.2.0' # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'pg', '~> 0.20.0' # Use postgresql as the database for Active Record
gem "dotenv-rails", '~> 2.4.0' # Adds the `ENV['BLEH']` ability to access environment variables
gem 'sass-rails', '~> 5.0' # Use SCSS for stylesheets
gem 'puma', '~> 3.11' # Use Puma as the app server
gem 'uglifier', '>= 1.3.0' # Use Uglifier as compressor for JavaScript assets
gem 'turbolinks', '~> 5' # Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'jbuilder', '~> 2.5' # Build JSON APIs with ease, not really being used.
gem 'shopify_app' # Shopify Application Rails engine and generator
gem 'shopify_api', '~> 4.11.0'
gem 'jquery-rails', '~> 4.3', '>= 4.3.3' # Use jquery as the JavaScript library
gem 'kaminari', '~> 1.1', '>= 1.1.1' # Pagination such as `Product.all.page(params[:page])`
gem 'rack-cors', require: 'rack/cors' # used for Cross-Origin Resource Sharing (CORS) serve public assets


# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

group :production do
  # solves the problem of production environment requests for assets (eg: application.css) returning a 404
  # because they do not contain a digest (eg: application-1c8db23293725a8857e5132d59211909.css).
  gem 'smart_assets', '~> 0.4.0'
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

