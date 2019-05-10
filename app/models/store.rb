class Store < ActiveRecord::Base
  include ShopifyApp::SessionStorage
  has_many :locations, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_many :users, dependent: :destroy
  has_one :subscription, dependent: :destroy

  before_create :generate_keys
  before_save :nil_default_templates
  before_save :see_if_footer_needs_update
  after_save :update_footer_asset!

  alias_attribute :email_template, :customer_confirm_email_tpl # Alias for reverse compatibility, can be removed probably by July 1, 2019
  alias_attribute :company_name, :name

  PERMITTED_PARAMS = [
    :top_msg, :success_msg, :show_phone, :show_instructions_from_customer, :active,
    :customer_confirm_email_tpl, :customer_confirm_email_tpl_enabled,
    :reserve_product_modal_tpl, :reserve_product_modal_tpl_enabled,
    :choose_location_modal_tpl, :choose_location_modal_tpl_enabled,
    :reserve_modal_faq_tpl, :reserve_modal_faq_tpl_enabled,
    :reserve_product_btn_tpl, :reserve_product_btn_tpl_enabled, :reserve_product_btn_selector, :reserve_product_btn_action,
    :stock_status_tpl, :stock_status_tpl_enabled, :stock_status_selector, :stock_status_action, :stock_status_behavior_when_stock_unknown, :stock_status_behavior_when_no_location_selected, :stock_status_behavior_when_no_nearby_locations_and_no_location,
    :custom_css, :custom_css_enabled
  ]

  JS_SCRIPT_PATH = "#{ENV['PUBLIC_CDN_BASE_PATH'].to_s.chomp('/')}/reserveinstore.js"

  def currency_template
    shopify_settings[:money_format].presence || '${{amount}}'
  end

  def integrator
    @integrator ||= StoreIntegrator.new(self)
  end

  def url
    "https://#{shopify_domain}"
  end
  alias_method :website_url, :url
  alias_method :company_website, :url

  def email
    shopify_settings[:email].to_s
  end

  def currency(val, opts = {})
    currency_template.gsub(/{{[ ]?amount[ ]?}}/, ActionController::Base.helpers.number_with_precision(val, precision: 2, delimeter: ','))
      .gsub(/{{[ ]?amount_with_comma_separator[ ]?}}/, ActionController::Base.helpers.number_with_precision(val, precision: 2, separator: ','))
  end

  def to_liquid
    {
      'top_msg' => top_msg,
      'show_phone' => show_phone,
      'show_instructions_from_customer' => show_instructions_from_customer,
      'success_msg' => success_msg,
      'faq' => reserve_modal_faq_tpl_in_use
    }
  end

  ##
  # Swap out our template to be nil if they are defaulted
  def nil_default_templates
    # Reset blank templates to `nil` so they don't get stuck in the DB
    [:stock_status_tpl, :reserve_product_btn_tpl, :reserve_modal_faq_tpl, :choose_location_modal_tpl, :reserve_product_modal_tpl, :customer_confirm_email_tpl].each do |tpl_attr|
      new_val = send(tpl_attr)
      next if new_val.nil?

      new_val = new_val.to_s.gsub(/\s/, '')
      default_val = try("default_#{tpl_attr}".to_sym).gsub(/\s/, '')

      if new_val.blank? || new_val == default_val
        self.send("#{tpl_attr}=".to_sym, nil)

        self.send("#{tpl_attr}_enabled=", false) if self.send("#{tpl_attr}_enabled?")
      end
    end
  end

  def top_msg
    attributes['top_msg'].presence || "Fill out the form below and we'll reserve the product at the location you specify."
  end

  ##
  # Display a product's price, check which currency the store is using, and render a string
  #
  # @param [String] money_amount "10.00"
  # @return [String] Price in the form of "$10.00"
  def price(money_amount)
    money_format.gsub(/{{[ ]?amount[ ]?}}/, ActionController::Base.helpers.number_with_precision(money_amount, precision: 2, delimeter: ','))
        .gsub(/{{[ ]?amount_with_comma_separator[ ]?}}/, ActionController::Base.helpers.number_with_precision(money_amount, precision: 2, separator: ','))
        .gsub(/{{[ ]?amount_no_decimals[ ]?}}/, ActionController::Base.helpers.number_with_precision(money_amount, precision: 0, separator: ','))
  end

  ##
  # Get store's money format from cache, hit Shopify Api if cache is missing
  # @return [String] Money format in the form of "${{amount}}"
  def money_format
    shopify_settings['money_format']
  end

  def cached_api
    with_shopify_session do
      @cached_api ||= Shopify::CachedApi.new(self)
    end
  end

  def api
    with_shopify_session do
      @api ||= Shopify::Api.new(self)
    end
  end

  def shopify_settings
    cached_api.shop.attributes.with_indifferent_access
  end

  def with_shopify_session
    @session ||= ShopifyAPI::Session.new(shopify_domain, shopify_token)
    ShopifyAPI::Base.activate_session(@session)
    yield(self) if block_given?
  end


  def shopify_link
    "<a href='https://#{shopify_domain}'>#{name}</a>"
  end

  ##
  # Ask Shopify for each location attached to this store
  # Ask Shopify for the store's email as well, to use as the default email for each location
  # Convert them into a Location instance, and save it to this store if it has an address
  def sync_locations!
    api.locations.each do |shopify_loc|
      loc = store.locations.find_by(platform_location_id: shopify_loc.id)
      if loc.present?
        loc.load_from_shopify(shopify_loc)
      else
        loc = Location.new_from_shopify(shopify_loc, store)
        loc.store_id = id
        loc.email = email
      end
    end
  end

  ##
  # @deprecated Temporary code and can be removed by May 31, 2019
  def fix_old_data!
    new_locations = api.locations.map do |shopify_loc|
      Location.new_from_shopify(shopify_loc, self)
    end

    locations.where(platform_location_id: nil).find_each do |old_location|
      new_locations.each do |new_location|
        match = old_location.attributes.except('id', 'created_at', 'updated_at', 'store_id', 'email', 'platform_location_id').keys.all? do |attr_key|
          new_location.attributes[attr_key] == old_location.attributes[attr_key]
        end

        if match
          ForcedLogger.log("Updating location with platform ID of #{new_location.platform_location_id}...", location: old_location.id, store: id)
          old_location.update(platform_location_id: new_location.platform_location_id)
        end
      end
    end

    locations.where("length(country) = 2").each do |location|
      if location.update(country: Carmen::Country.coded(location.country).name)
        ForcedLogger.log("Fixed location country code to country name.", location: location.id, store: id)
      end
    end

    ForcedLogger.log("Ensuring all webhooks are installed...")
    ShopifyApp::WebhooksManager.queue(
      shopify_domain,
      shopify_token,
      ShopifyApp.configuration.webhooks
    )

    ForcedLogger.log("Ensuring all scripts are installed...")
    ShopifyApp::ScripttagsManager.queue(
      shopify_domain,
      shopify_token,
      ShopifyApp.configuration.scripttags
    )

    update_footer_asset!

    true
  end

  ######################################################
  # For Custom Email Templates

  ##
  # @return [Text] - default, un-rendered email template
  def self.default_customer_confirm_email_tpl
    return @default_customer_confirm_email_tpl if @default_customer_confirm_email_tpl.present? && !Rails.env.development?

    @default_customer_confirm_email_tpl = ApplicationController.new.render_to_string(partial: 'customer_mailer/customer_confirm_email_tpl')
  end
  def self.default_email_template; default_customer_confirm_email_tpl; end # Alias for reverse compatibility, can be removed probably by July 1, 2019
  def default_customer_confirm_email_tpl; self.class.default_customer_confirm_email_tpl; end

  ##
  # @return [Text] - The template we want to use for emails for this store
  def customer_confirm_email_tpl_in_use
    if customer_confirm_email_tpl_enabled? && customer_confirm_email_tpl.present?
      customer_confirm_email_tpl.to_s
    else
      self.class.default_customer_confirm_email_tpl
    end
  end
  alias_method :email_template_in_use, :customer_confirm_email_tpl_in_use # Alias for reverse compatibility, can be removed probably by July 1, 2019

  ##
  # @return [Hash] - liquid params used by JS email previewer
  def preview_email_liquid_params
    {'customer_first_name' => "John",
     'customer_last_name' => "Doe",
     'product_link' => "<a href=\"#\">Apple (Red)</a>",
     'location_name' => "Store 3",
     'location_address' => "1234 Test St.",
     'location_city' => "City",
     'location_state' => "State",
     'location_country' => "Country",
     'store_link' => "<a href=\"#\">Store 3</a>",
     "reservation_time" => "Monday at 5:30pm"}
  end



  ######################################################
  # For FAQ TPL


  def self.default_reserve_modal_faq_tpl
    return @default_reserve_modal_faq_tpl if @default_reserve_modal_faq_tpl.present? && !Rails.env.development?

    @default_reserve_modal_faq_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/faq/default_tpl.liquid.html')
  end
  def default_reserve_modal_faq_tpl; self.class.default_reserve_modal_faq_tpl; end
  def reserve_modal_faq_tpl_in_use
    if reserve_modal_faq_tpl_enabled?
      reserve_modal_faq_tpl.to_s
    else
      self.class.default_reserve_modal_faq_tpl
    end
  end



  ######################################################
  # For Reserve Modal TPL

  def self.default_reserve_product_modal_tpl
    return @default_reserve_product_modal_tpl if @default_reserve_product_modal_tpl.present? && !Rails.env.development?

    @default_reserve_product_modal_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/modal/default_tpl.liquid.html')
  end
  def default_reserve_product_modal_tpl; self.class.default_reserve_product_modal_tpl; end
  def reserve_product_modal_tpl_in_use
    if reserve_product_modal_tpl_enabled?
      reserve_product_modal_tpl.to_s
    else
      self.class.default_reserve_product_modal_tpl
    end
  end


  ######################################################
  # For Locations Modal TPL

  def self.default_choose_location_modal_tpl
    return @default_choose_location_modal_tpl if @default_choose_location_modal_tpl.present? && !Rails.env.development?

    @default_choose_location_modal_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/locations/modal/default_tpl.liquid.html')
  end
  def default_choose_location_modal_tpl; self.class.default_choose_location_modal_tpl; end
  def choose_location_modal_tpl_in_use
    if choose_location_modal_tpl_enabled?
      choose_location_modal_tpl.to_s
    else
      self.class.default_choose_location_modal_tpl
    end
  end



  ######################################################
  # Reserve Button TPL


  def self.default_reserve_product_btn_tpl
    return @default_reserve_product_btn_tpl if @default_reserve_product_btn_tpl.present? && !Rails.env.development?

    @default_reserve_product_btn_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/btn/default_tpl.liquid.html')
  end
  def default_reserve_product_btn_tpl; self.class.default_reserve_product_btn_tpl; end
  def reserve_product_btn_tpl_in_use
    if reserve_product_btn_tpl_enabled?
      reserve_product_btn_tpl.to_s
    else
      self.class.default_reserve_product_btn_tpl
    end
  end


  ######################################################
  # Stock Status TPL


  def self.default_stock_status_tpl
    return @default_stock_status_tpl if @default_stock_status_tpl.present? && !Rails.env.development?

    @default_stock_status_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/stock_status/default_tpl.liquid.html')
  end
  def default_stock_status_tpl; self.class.default_stock_status_tpl; end
  def stock_status_tpl_in_use
    if stock_status_tpl_enabled?
      stock_status_tpl.to_s
    else
      self.class.default_stock_status_tpl
    end
  end



  ##
  # @return [Hash] - liquid params used by JS email previewer
  def frontend_tpl_vars
    {
      locations: locations.to_a,
      cdn_url: ENV['PUBLIC_CDN_BASE_PATH'],
      settings: self
    }
  end

  def custom_css_in_use
    custom_css_enabled? ? custom_css.to_s : ''
  end

  def footer_config
    {
      reserve_product_btn: {
        tpl: reserve_product_btn_tpl_in_use,
        selector: reserve_product_btn_selector,
        action: reserve_product_btn_action
      },
      stock_status: {
        tpl: stock_status_tpl_in_use,
        selector: stock_status_selector,
        action: stock_status_action,
        behavior_when: {
          stock_unknown: stock_status_behavior_when_stock_unknown,
          no_location_selected: stock_status_behavior_when_no_location_selected,
          no_nearby_locations_and_no_location: stock_status_behavior_when_no_nearby_locations_and_no_location,
        }
      },
      api_url: ENV['BASE_APP_URL'],
      store_pk: public_key
    }
  end

  def trial_days_left
    plan = subscription.try(:plan) || recommended_plan
    return nil if plan.blank?

    [plan.trial_days - ((Time.now.utc.to_i - created_at.to_i)/1.day), 0].max.ceil
  end

  def activate!
    self.active = true
    save!
  end

  def deactivate!
    self.active = false
    save!
  end

  def user; users.first; end

  def recommended_plan
    plan_code = recommended_plan_code
    return nil if plan_code.blank?
    @recommended_plan ||= Plan.find_by(code: plan_code)
  end

  def recommended_plan_code
    case locations.count
    when 0
      nil
    when 1
      'startup'
    when 2..3
      'small'
    when 4..10
      'medium'
    when 11..100
      'large'
    else
      'enterprise'
    end
  end

  def needs_subscription?
    subscription.blank? && recommended_plan.present?
  end

  private

  ##
  # Generate public and secret key before new store being saved
  def generate_keys
    self.public_key = generate_key('pk_')
    self.secret_key = generate_key('sk_')
  end

  ##
  # @param [String] prefix prefix for the generated key
  # @return [String] generated key based on time and random number
  def generate_key(prefix = "")
    prefix.to_s + Digest::SHA256.hexdigest(prefix.to_s + Time.current.to_f.to_s + rand(99999).to_s)
  end

  def see_if_footer_needs_update
    @footer_needs_update = changed_attributes.keys.any?{ |attr| attr.to_s =~ /active|reserve_product_btn.*|custom_css.*|stock_status.*/i }
    true
  end

  def update_footer_asset!
    if @footer_needs_update
      UpdateFooterJob.perform_later(self.id)
      @footer_needs_update = false
    end
    true
  end

end
