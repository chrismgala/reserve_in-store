source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.7'

gem 'ace-rails-ap', '~> 4.1.4' # For making HTML editors look pretty
gem 'activemodel_flags', "~> 0.2.0" # For simple flagging of models
gem 'bootsnap', '>= 1.4.6', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'bootstrap','~> 4.3.1' # For our theme
gem 'carmen', '~> 1.0.2' # For figuring out what the country/region names of a country code or region code are.
gem 'chosen-rails', '~> 1.9'# To do much nicer drop downs with built-in searches
gem 'dalli', '~> 2.7.6' # For memcached caching in production only
gem 'devise' # For admin logins.
gem 'dotenv-rails', '~> 2.4.0' # Adds the `ENV['BLEH']` ability to access environment variables
gem 'httparty', '~> 0.13.7' # To party... and to do some really easy HTTP requests for things such as pulling the CSS content from the store for previews
gem 'jbuilder', '~> 2.5' # Build JSON APIs with ease, not really being used.
gem 'jquery-rails', '~> 4.3', '>= 4.3.3' # Use jquery as the JavaScript library
gem 'kaminari', '~> 1.1', '>= 1.1.1' # Pagination such as `Product.all.page(params[:page])`
gem 'local_time', '~> 2.0.1' # For admin and merchant-facing pretty time.
gem 'mechanize', '~> 2.7.5' # For scraping and parsing store data for the purposes of better previews (such as in StoreCrawler)
gem 'non-stupid-digest-assets', '~> 1.0.9' # used for compiling both digest and non-digest assets in production
gem 'liquid', '~> 4.0.0' # For rendering liquid templates that we use to theme the displays. We allow them to customize our liquid templates.
gem 'pg', '~> 0.20.0' # Use postgresql as the database for Active Record
gem 'puma', '~> 3.11' # Use Puma as the app server
gem "intercom-rails", '~> 0.4.0' # For live chat, support and knowledgebase
gem 'rack-cors', require: 'rack/cors' # used for Cross-Origin Resource Sharing (CORS) serve public assets
gem 'rails', '~> 5.2.4.1' # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rainbow', '~> 3.0.0'  # Ruby gem for colorizing printed text on ANSI terminals
gem 'sass-rails', '~> 5.0' # Use SCSS for stylesheets
gem 'scout_apm', '~>2.6.7' # For performance monitoring
gem 'sentry-raven', '~> 2.7.4' # For bug tracking
gem 'shopify_api', '~> 9.0.2'
gem 'shopify_app', '~> 13.0.0' # Shopify Application Rails engine and generator
gem "slack-notifier", '~> 2.3.2' # For sending notifications to slack
gem 'sprockets-es6', '~> 0.9.2' # For es6 automatic compilation
gem 'to_bool', '~> 1.0.1' # For easy parsing of boolean values in params
gem 'turbolinks', '~> 5' # Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'uglifier', '>= 1.3.0' # Use Uglifier as codampressor for JavaScript assets
gem 'rails_same_site_cookie', '0.1.5' # Allow all cookies to be fetched in a 3rd party context, since we are an embedded app

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


  unless ENV['RUBYMINE']
    gem 'pry', '~> 0.11.3'
    gem 'pry-byebug', '~> 3.6.0'
    gem 'pry-rails', '~> 0.3.6'
    gem 'pry-remote', '~> 0.1.8'
    gem 'pry-rescue', '~> 1.4.5'
    gem 'pry-stack_explorer', '~> 0.4.9.2'

  end
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

