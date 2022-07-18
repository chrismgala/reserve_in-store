class Store < ApplicationRecord
  include ShopifyApp::ShopSessionStorage

  has_many :locations, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_many :users, dependent: :destroy
  has_one :subscription, dependent: :destroy

  before_create :generate_keys
  before_save :nil_default_templates
  before_save :see_if_footer_needs_update
  after_save :update_footer_asset!, :clear_api_cache!

  alias_attribute :email_template, :customer_confirm_email_tpl # Alias for reverse compatibility, can be removed probably by July 1, 2019
  alias_attribute :company_name, :name

  PERMITTED_PARAMS = [
    :top_msg, :success_msg, :show_phone, :show_instructions_from_customer, :active,
    :customer_confirm_email_tpl, :customer_confirm_email_tpl_enabled,
    :location_notification_email_tpl, :location_notification_email_tpl_enabled,
    :reserve_modal_tpl, :reserve_modal_tpl_enabled,
    :choose_location_modal_tpl, :choose_location_modal_tpl_enabled,
    :reserve_modal_faq_tpl, :reserve_modal_faq_tpl_enabled,
    :reserve_product_btn_tpl, :reserve_product_btn_tpl_enabled, :reserve_product_btn_selector, :reserve_product_btn_action,
    :reserve_cart_btn_tpl, :reserve_cart_btn_tpl_enabled, :reserve_cart_btn_selector, :reserve_cart_btn_action,
    :stock_status_tpl, :stock_status_tpl_enabled, :stock_status_selector, :stock_status_action, :stock_status_behavior_when_stock_unknown,
    :stock_status_behavior_when_no_location_selected, :stock_status_behavior_when_no_nearby_locations_and_no_location,
    { webhooks: [ :url, :auth_token, topic: [] ] },
    :show_when_only_available_online,
    :custom_css, :custom_css_enabled,
    :location_notification_subject, :customer_confirmation_subject,
    :location_notification_sender_name, :customer_confirmation_sender_name,
    :show_additional_fields, :webhooks_enabled, :stock_threshold, :hide_location_search,
    :reservation_fulfilled_send_notification, :reservation_unfulfilled_send_notification,
    :fulfilled_reservation_notification_email_tpl, :fulfilled_reservation_notification_email_tpl_enabled,
    :unfulfilled_reservation_notification_email_tpl, :unfulfilled_reservation_notification_email_tpl_enabled,
    :fulfilled_reservation_subject, :unfulfilled_reservation_subject,
    :fulfilled_reservation_sender_name, :unfulfilled_reservation_sender_name,
    :checkout_without_clearing_cart, :discount_code,
    :checkout_success_message_tpl_enabled, :checkout_success_message_tpl,
    show_stock_status_labels: {}
  ]

  JS_SCRIPT_PATH = "#{ENV['PUBLIC_CDN_BASE_PATH'].to_s.chomp('/')}/reserveinstore.js"


  def api_version
    ShopifyApp.configuration.api_version
  end

  ##
  # Get store's money format from cache, hit Shopify Api if cache is missing
  # @return [String] Money format in the form of "${{amount}}"
  def currency_template
    shopify_settings[:money_format].presence || '${{amount}}'
  end
  alias_method :money_format, :currency_template

  def integrator
    @integrator ||= StoreIntegrator.new(self)
  end

  def url
    "https://#{shopify_domain}"
  end

  def website_url
    "https://#{shopify_settings[:domain].to_s.gsub(/https?:\/\//i, '')}"
  end
  alias_method :website_url, :url
  alias_method :company_website, :website_url

  def website_link
    "<a href=\"#{website_url}\" target=\"_blank\">#{name}</a>"
  end

  def support_email
    shopify_settings[:customer_email].presence || email
  end

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
      'show_additional_fields' => show_additional_fields,
      'success_msg' => success_msg,
      'faq' => reserve_modal_faq_tpl_in_use,
      'hide_location_search' => hide_location_search,
      'checkout_without_clearing_cart' => checkout_without_clearing_cart,
    }
  end

  ##
  # Swap out our template to be nil if they are defaulted
  def nil_default_templates
    # Reset blank templates to `nil` so they don't get stuck in the DB
    tpl_attr = attributes.keys.find_all{|k| k.to_s =~ /^.+_tpl$/i }.map{ |k| k.to_sym }
    tpl_attr.each do |tpl_attr|
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
  # @param [Float|String|Integer] val 10.0
  # @return [String] Price in the form of "$10.00"
  def format_currency(val, opts = {})
    formatted_str = currency_template
    val = val.to_f
    formatted_str = formatted_str
                      .gsub(/{{[ ]?amount[ ]?}}/, ActionController::Base.helpers.number_with_precision(val, precision: 2, delimiter: ','))
    formatted_str = formatted_str
                      .gsub(/{{[ ]?amount_no_decimals[ ]?}}/, ActionController::Base.helpers.number_with_precision(val, precision: 0, delimiter: ','))
                      .gsub(/^(.+)\.00$/, '\1')
    formatted_str.gsub(/{{[ ]?amount_with_comma_separator[ ]?}}/, ActionController::Base.helpers.number_with_precision(val, precision: 2, separator: ','))
  end
  alias_method :price, :format_currency
  alias_method :currency, :format_currency


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
    @session ||= ShopifyAPI::Session.new(domain: shopify_domain, token: shopify_token, api_version: "#{ShopifyApp.configuration.api_version}")
    ShopifyAPI::Base.activate_session(@session)
    yield(self) if block_given?
  end

  def shopify_app_path
    ENV['SHOPIFY_APP_PATH_TOKEN'].presence || 'reserve-in-store-by-fera'
  end

  def shopify_app_link
    "<a href=\"https://#{shopify_domain}/admin/apps/#{shopify_app_path}\">#{name}</a>"
  end

  ##
  # Ask Shopify for each location attached to this store
  # Ask Shopify for the store's email as well, to use as the default email for each location
  # Convert them into a Location instance, and save it to this store if it has an address
  def sync_locations!
    api.locations.each do |shopify_loc|
      loc = locations.find_by(platform_location_id: shopify_loc.id)
      if loc.present?
        loc.load_from_shopify(shopify_loc.attributes)
      else
        loc = Location.new_from_shopify(shopify_loc, self)
        loc.store_id = id
        loc.email = email
        loc.save!
      end
    end
  end


  ######################################################
  # For Custom Email Templates

  ##
  # @return [Text] - default, un-rendered email template
  def self.default_customer_confirm_email_tpl
    return @default_customer_confirm_email_tpl if @default_customer_confirm_email_tpl.present? && !Rails.env.development?

    @default_customer_confirm_email_tpl = ApplicationController.new.render_to_string(partial: 'reservation_mailer/default_templates/customer_confirm_email_tpl')
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
  # @return [Text] - default, un-rendered email template
  def self.default_unfulfilled_reservation_notification_email_tpl
    return @default_unfulfilled_reservation_notification_email_tpl if @default_unfulfilled_reservation_notification_email_tpl.present? && !Rails.env.development?
    @default_unfulfilled_reservation_notification_email_tpl = ApplicationController.new.render_to_string(partial: 'reservation_mailer/default_templates/unfulfilled_reservation_notification_email_tpl')
    end
  def default_unfulfilled_reservation_notification_email_tpl; self.class.default_unfulfilled_reservation_notification_email_tpl; end

  ##
  # @return [Text] - The template we want to use for unfulfilled emails for this store
  def unfulfilled_reservation_notification_email_tpl_in_use
    if unfulfilled_reservation_notification_email_tpl_enabled? && unfulfilled_reservation_notification_email_tpl.present?
      unfulfilled_reservation_notification_email_tpl.to_s
    else
      self.class.default_unfulfilled_reservation_notification_email_tpl
    end
  end

  ##
  # @return [Text] - default, un-rendered email template
  def self.default_fulfilled_reservation_notification_email_tpl
    return @default_fulfilled_reservation_notification_email_tpl if @default_fulfilled_reservation_notification_email_tpl.present? && !Rails.env.development?
    @default_fulfilled_reservation_notification_email_tpl = ApplicationController.new.render_to_string(partial: 'reservation_mailer/default_templates/fulfilled_reservation_notification_email_tpl')
    end
  def default_fulfilled_reservation_notification_email_tpl; self.class.default_fulfilled_reservation_notification_email_tpl; end

  ##
  # @return [Text] - The template we want to use for fulfilled emails for this store
  def fulfilled_reservation_notification_email_tpl_in_use
    if fulfilled_reservation_notification_email_tpl_enabled? && fulfilled_reservation_notification_email_tpl.present?
      fulfilled_reservation_notification_email_tpl.to_s
    else
      self.class.default_fulfilled_reservation_notification_email_tpl
    end
  end

  ##
  # @return [Text] - default, un-rendered email template
  def self.default_location_notification_email_tpl
    return @default_location_notification_email_tpl if @default_location_notification_email_tpl.present? && !Rails.env.development?

    @default_location_notification_email_tpl = ApplicationController.new.render_to_string(partial: 'reservation_mailer/default_templates/location_notification_email_tpl')
  end
  def default_location_notification_email_tpl; self.class.default_location_notification_email_tpl; end

  ##
  # @return [Text] - The template we want to use for emails for this store
  def location_notification_email_tpl_in_use
    if location_notification_email_tpl_enabled? && location_notification_email_tpl.present?
      location_notification_email_tpl.to_s
    else
      self.class.default_location_notification_email_tpl
    end
  end

  ######################################################
  # For FAQ TPL


  def self.default_reserve_modal_faq_tpl
    return @default_reserve_modal_faq_tpl if @default_reserve_modal_faq_tpl.present? && !Rails.env.development?

    @default_reserve_modal_faq_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/default_templates/faq.liquid.html')
  end
  def default_reserve_modal_faq_tpl; self.class.default_reserve_modal_faq_tpl; end
  def reserve_modal_faq_tpl_in_use
    if reserve_modal_faq_tpl_enabled?
      reserve_modal_faq_tpl.to_s
    else
      self.class.default_reserve_modal_faq_tpl
    end
  end


  ##
  # Checkout success message tpl
  # @return [Text] - default, un-rendered email template
  def self.default_checkout_success_message_tpl
    return @default_checkout_success_message_tpl if @default_checkout_success_message_tpl.present? && !Rails.env.development?

    @default_checkout_success_message_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/default_templates/checkout_success_message.liquid.html')
  end
  def default_checkout_success_message_tpl; self.class.default_checkout_success_message_tpl; end

  ##
  # @return [Text] - Template we want to use for checkout success message email for this store
  def checkout_success_message_tpl_in_use
    if checkout_success_message_tpl_enabled?
      checkout_success_message_tpl.to_s
    else
      self.class.default_checkout_success_message_tpl
    end
  end


  ######################################################
  # For Reserve Modal TPL

  def self.default_reserve_modal_tpl
    return @default_reserve_modal_tpl if @default_reserve_modal_tpl.present? && !Rails.env.development?

    @default_reserve_modal_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/default_templates/reserve_modal.liquid.html')
  end
  def default_reserve_modal_tpl; self.class.default_reserve_modal_tpl; end
  def reserve_modal_tpl_in_use
    if reserve_modal_tpl_enabled?
      reserve_modal_tpl.to_s
    else
      self.class.default_reserve_modal_tpl
    end
  end


  ######################################################
  # For Locations Modal TPL

  def self.default_choose_location_modal_tpl
    return @default_choose_location_modal_tpl if @default_choose_location_modal_tpl.present? && !Rails.env.development?

    @default_choose_location_modal_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/locations/default_templates/choose_location_modal.liquid.html')
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
  # Product Reserve Button TPL


  def self.default_reserve_product_btn_tpl
    return @default_reserve_product_btn_tpl if @default_reserve_product_btn_tpl.present? && !Rails.env.development?

    @default_reserve_product_btn_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/default_templates/reserve_product_btn.liquid.html')
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
  # Cart Reserve Button TPL


  def self.default_reserve_cart_btn_tpl
    return @default_reserve_cart_btn_tpl if @default_reserve_cart_btn_tpl.present? && !Rails.env.development?

    @default_reserve_cart_btn_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/default_templates/reserve_cart_btn.liquid.html')
  end
  def default_reserve_cart_btn_tpl; self.class.default_reserve_cart_btn_tpl; end
  def reserve_cart_btn_tpl_in_use
    if reserve_cart_btn_tpl_enabled?
      reserve_cart_btn_tpl.to_s
    else
      self.class.default_reserve_cart_btn_tpl
    end
  end


  ######################################################
  # Stock Status TPL


  def self.default_stock_status_tpl
    return @default_stock_status_tpl if @default_stock_status_tpl.present? && !Rails.env.development?

    @default_stock_status_tpl = ApplicationController.new.render_to_string(partial: 'api/v1/reservations/default_templates/stock_status.liquid.html')
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
  def frontend_tpl_vars(params = {})
    params[:product_tag_filter] = '' if params[:product_tag_filter].nil?

    if params[:current_page] == "product"
      current_page_condition = "visible_in_product = true"
    else
      current_page_condition = "visible_in_cart = true"
    end
    product_tag_condition = "(string_to_array(product_tag_filter,',')::text[]) && (ARRAY[?]::text[]) OR product_tag_filter = ? OR product_tag_filter IS NULL ", params[:product_tag_filter], ''
    {
      locations: (locations.where(product_tag_condition)
                    .where(current_page_condition)
                 ).order("name").to_a.map { |loc| loc.to_liquid },
      cdn_url: ENV['PUBLIC_CDN_BASE_PATH'],
      settings: self
    }.with_indifferent_access
  end

  def custom_css_in_use
    custom_css_enabled? ? custom_css.to_s : ''
  end

  def auto_product_btn_location?
    reserve_product_btn_action == 'auto'
  end

  def auto_cart_btn_location?
    reserve_cart_btn_action == 'auto'
  end

  def auto_stock_status_location?
    stock_status_action == 'auto'
  end

  def footer_config
    {
      reserve_product_btn: {
        tpl: reserve_product_btn_tpl_enabled? ? reserve_product_btn_tpl_in_use : nil,
        selector: auto_product_btn_location? ? nil : reserve_product_btn_selector,
        action: auto_product_btn_location? ? nil : reserve_product_btn_action
      },
      reserve_cart_btn: {
        tpl: reserve_cart_btn_tpl_enabled? ? reserve_cart_btn_tpl_in_use : nil,
        selector: auto_cart_btn_location? ? nil : reserve_cart_btn_selector,
        action: auto_cart_btn_location? ? nil : reserve_cart_btn_action
      },
      stock_status: {
        tpl: stock_status_tpl_enabled? ? stock_status_tpl_in_use : nil,
        selector: auto_stock_status_location? ? nil : stock_status_selector,
        action: auto_stock_status_location? ? nil : stock_status_action,
        behavior_when: {
          stock_unknown: stock_status_behavior_when_stock_unknown,
          no_location_selected: stock_status_behavior_when_no_location_selected,
          no_nearby_locations_and_no_location: stock_status_behavior_when_no_nearby_locations_and_no_location,
          show_when_only_available_online: show_when_only_available_online
        },
        stock_label: show_stock_status_labels
      },
      discount_code: discount_code,
      checkout_without_clearing_cart: checkout_without_clearing_cart,
      checkout_success_message_tpl: checkout_success_message_tpl_in_use,
      api_url: ENV['BASE_APP_URL'],
      store_pk: public_key
    }
  end

  ##
  # By default, connection errors are ignored, so it is up the store's adapter to decide if the caught error is real or not.
  # @param e [StandardError]
  def is_connection_error?(e)
    return true if [ActiveResource::UnauthorizedAccess, ActiveResource::ResourceNotFound, ActiveResource::ForbiddenAccess].include?(e.class)
    return true if e.message =~ /.*((Net::(HTTPPaymentRequired|HTTPNotFound))|Payment Required|Locked).*/i
    false
  end

  def update_connection!
    update_connection
    save!
  end

  def check_connected?
    update_connection! if last_connected_at.blank? || last_connected_at < 1.hour.ago

    connected?
  end

  def update_connection
    self.connection_error = fetch_connection_error
    if connection_error.blank?
      self.last_connected_at = nil
    elsif last_connected_at.blank?
      self.last_connected_at = Time.now
    end
  end

  def connected?
    update_connection if last_connected_at.blank? || last_connected_at < 1.hour.ago

    connection_error.blank?
  end

  ##
  # @return [String|NiClass] Nil on success, the error class as a string on failure.
  def fetch_connection_error
    # ::Bananastand::StoreCrawler.new(self, raise_errors: true).read_url

    api.store_information.present?

    yield if block_given?

    nil
  rescue StandardError => e
    if is_connection_error?(e)
      e.inspect
    else
      ForcedLogger.log("Fetching connection got unrecognized error so assumed the store is still connected. Error was: #{e.inspect}", store: id)
      nil
    end
  end

  ##
  # @return [Boolean] True if store is disconnected (we no longer have access), false otherwise.
  def disconnected?
    api.store_information
    false
  rescue ActiveResource::UnauthorizedAccess, ActiveResource::ResourceNotFound, ActiveResource::ClientError
    true
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

  def trial_days_left
    plan = subscription.try(:plan) || recommended_plan
    return nil if plan.blank?

    return ((trial_extend_date.to_i - Time.now.utc.to_i)/1.day + 1) if trial_extend_date.present?

    [plan.trial_days - ((Time.now.utc.to_i - created_at.to_i)/1.day), 0].max.ceil

  end

  def recommended_plan
    plan_code = recommended_plan_code
    return nil if plan_code.blank?
    @recommended_plan ||= Plan.find_by(code: plan_code)
  end

  def override_subscriptions!(value, overriding, user_id, add_admin_notes = nil)
    self.add_admin_note(add_admin_notes, user_id)
    if overriding == "recommended_plan" && value!=""
      self.plan_overrides = { code: value }
    else
      self.plan_overrides = {}
    end

    save!
  end

  def add_admin_note(note, user_id)
    if note.present?
      user             = Admin.find(user_id)
      self.admin_notes = self.admin_notes.present? ? self.admin_notes + "\n" : ""
      self.admin_notes += "#{Time.now}: #{note} - #{user.email} (id #{user.id})"
    end
  end

  def distinctly_named_location_count
    @distinctly_named_location_count ||= locations.pluck(:name).to_a.uniq.count
  end

  def recommended_plan_code
    if plan_overrides.to_h['code'].present?
      return plan_overrides.to_h['code']
    end

    # See https://docs.google.com/spreadsheets/d/1aeZr4BI_tFWwWZRWqV3xUqErYdDS6gf0Izli35QYKzE/edit?usp=sharing
    case distinctly_named_location_count
      when 0 then nil
      when 1..2 then 'startup'
      when 3..6 then 'small'
      when 7..20 then 'medium'
      when 21..50 then 'medium-2'
      when 51..250 then 'large'
      when 251..417 then 'large-2'
      else 'enterprise'
    end
  end

  def recommended_feature_plan(feature_key)
    plan_code = recommended_feature_plan_code(feature_key)
    return nil if plan_code.blank?
    Plan.find_by(code: plan_code)
  end

  def recommended_feature_plan_code(feature_key)
    if plan_overrides.to_h['code'].present?
      return plan_overrides.to_h['code']
    end

    min_plan = Plan.find_by("(features ->> '#{feature_key}')::boolean")
    min_plan.code
  end

  def sandbox_store?
    return false if fera_team_actual_live_view?
    shopify_settings.try(:[], :plan_name).to_s.downcase.include?('affiliate')
  end

  ##
  # It is difficult to test subscription live because sandbox and in_development is true
  # we can use is_fera_team but just wanted to allow some email
  # to make it easier for our team to test allow email with ristest to see everything similar to actual site
  def fera_team_actual_live_view?
    user.email.to_s.downcase.include?('ristest')
  end

  ##
  # Is this store a dev store that has not been launched yet?
  def in_development?
    return false if fera_team_actual_live_view?
    return true if name.to_s =~ /test|dev(elopment|eloper)?[^a-z]|example|sample|staging|ris/i
    return true if shopify_domain.to_s =~ /test|dev(elopment|eloper)?[^a-z]|example|sample|staging|ris/i
    false
  end

  def is_fera_team?
    email.to_s =~ /.*@(fera|reserveinstore|bananastand|wellfounded).*/i
  end

  def subscribed?
    subscription.try(:id).present?
  end

  def needs_subscription?
    return false if sandbox_store?
    return false if in_development?
    subscription.blank? && recommended_plan.present?
  end

  def needs_upgrade_subscription?
    return false if sandbox_store?
    return false if in_development?
    subscription.present?
  end

  def trial_ends_at
    return trial_extend_date if trial_extend_date.present?
    (created_at + 30.days).to_datetime
  end

  def extend_trial!(time_length, user_id, admin_note)
    trial_ends = created_at + 30.days

    trial_ends = trial_extend_date if trial_extend_date.present?
    self.trial_extend_date = trial_ends + time_length.to_i

    self.add_admin_note(admin_note, user_id)
    save!
  end

  def reauthorize_subscription?
    return true if plan_overrides.to_h['code'].present? && plan_overrides.to_h['code'] != subscription.plan_attributes.to_h['code']
    return true if trial_extend_date.present? && trial_extend_date != trial_ends_at

    false
  end

  def add_webhook(topic, url)
    clean_topic = topic.gsub(/\/(destroyed|deleted|destroy)/i, '/delete')
                    .gsub(/\/(updated|saved|save|updates)/i, '/update')
                    .gsub(/\/(new|creates)/i, '/create')
                    .gsub(/\/(fulfill|fulfills)/i, '/fulfilled')
    self.webhooks = webhooks.to_a + [{ topic: clean_topic, url: url }]
  end

  def webhooks
    super.to_a
  end

  def permitted_attribute_changed?
    changed_attributes.keys.any? do |attr|
      PERMITTED_PARAMS.any? do |param|
        if param.is_a?(Hash)
          param.keys.any?{ |key| key.to_s == attr.to_s }
        else
          attr.to_s == param.to_s
        end
      end
    end
  end
  alias_method :permitted_attributes_changed?, :permitted_attribute_changed?

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
    @footer_needs_update = permitted_attribute_changed?
    true
  end

  def update_footer_asset!
    if @footer_needs_update
      UpdateFooterJob.perform_now(self.id)
      @footer_needs_update = false
    end
    true
  end

  def clear_api_cache!
    cached_api.clear_cache!

    true
  end

end
