IntercomRails.config do |config|
  # == Intercom app_id
  #
  config.app_id = ENV["INTERCOM_APP_ID"] || "err9lm2u"

  # == Intercom session_duration
  # make session expires after 8 hours rather than the default 3.5 days
  config.session_duration = 28800

  # == Intercom secret key
  # This is required to enable secure mode, you can find it on your Setup
  # guide in the "Secure Mode" step.
  #
  config.api_secret = ENV["INTERCOM_APP_SECRET"]

  # == Enabled Environments
  # Which environments is auto inclusion of the Javascript enabled for
  #
  config.enabled_environments = ["development", "production"]

  # == Current user method/variable
  # The method/variable that contains the logged in user in your controllers.
  # If it is `current_user` or `@user`, then you can ignore this
  #
  # config.user.current = Proc.new { current_user }
  # config.user.current = [Proc.new { current_user }]

  # == Include for logged out Users
  # If set to true, include the Intercom messenger on all pages, regardless of whether
  # The user model class (set below) is present. Only available for Apps on the Acquire plan.
  # config.include_for_logged_out_users = true

  # == User model class
  # The class which defines your user model
  #
  # config.user.model = Proc.new { User }

  # == Lead/custom attributes for non-signed up users
  # Pass additional attributes to for potential leads or
  # non-signed up users as an an array.
  # Any attribute contained in config.user.lead_attributes can be used
  # as custom attribute in the application.
  # config.user.lead_attributes = %w(ref_data utm_source)

  # == Exclude users
  # A Proc that given a user returns true if the user should be excluded
  # from imports and Javascript inclusion, false otherwise.
  #
  # config.user.exclude_if = Proc.new { |user| user.deleted? }

  # == User Custom Data
  # A hash of additional data you wish to send about your users.
  # You can provide either a method name which will be sent to the current
  # user object, or a Proc which will be passed the current user.
  #
  config.user.custom_data = {
    :user_id => Proc.new { |current_user| @current_user.try(:id) },
    :user_group => Proc.new { |current_user| @current_user.try(:user_group) }
  }

  # == Current company method/variable
  # The method/variable that contains the current company for the current user,
  # in your controllers. 'Companies' are generic groupings of users, so this
  # could be a company, app or group.
  #
  config.company.current = Proc.new { @current_store }

  # == Exclude company
  # A Proc that given a company returns true if the company should be excluded
  # from imports and Javascript inclusion, false otherwise.
  #
  # config.company.exclude_if = Proc.new { |app| app.subdomain == 'demo' }

  # == Company Custom Data
  # A hash of additional data you wish to send about a company.
  # This works the same as User custom data above.
  #
  config.company.custom_data = {
    :store_id => Proc.new { |store| store.try(:id) },
    :account_id => Proc.new { |store| store.try(:account).try(:id) },
    :store_url => Proc.new { |store| store.try(:url) },
    :store_name => Proc.new { |store| store.try(:name) },
    :store_trailing_30d_rev => Proc.new { |store| store.try(:trailing_30d_rev) },
    :store_trailing_30d_ord => Proc.new { |store| store.try(:trailing_30d_ord) },
    :store_type => Proc.new { |store| store.try(:type_name) },
    :review_written => Proc.new { |store| store.try(:review_written) },
  }

  # == Company Plan name
  # This is the name of the plan a company is currently paying (or not paying) for.
  # e.g. Messaging, Free, Pro, etc.
  #
  config.company.plan = Proc.new { |store| store.try(:subscription).try(:plan).try(:code) }

  # == Company Monthly Spend
  # This is the amount the company spends each month on your app. If your company
  # has a plan, it will set the 'total value' of that plan appropriately.
  #
  config.company.monthly_spend = Proc.new { |store| store.try(:subscription).try(:current_price) }

  # == Custom Style
  # By default, Intercom will add a button that opens the messenger to
  # the page. If you'd like to use your own link to open the messenger,
  # uncomment this line and clicks on any element with id 'Intercom' will
  # open the messenger.
  #
  # config.inbox.style = :custom
  #
  # If you'd like to use your own link activator CSS selector
  # uncomment this line and clicks on any element that matches the query will
  # open the messenger
  # config.inbox.custom_activator = '.intercom'
  #
  # If you'd like to hide default launcher button uncomment this line
  # config.hide_default_launcher = true
end
