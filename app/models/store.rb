class Store < ActiveRecord::Base
  include ShopifyApp::SessionStorage
  has_many :locations, dependent: :destroy
  has_many :reservations

  before_create :generate_keys
  before_save :nil_default_templates

  alias_attribute :email_template, :customer_confirm_email_tpl # Alias for reverse compatibility, can be removed probably by July 1, 2019

  PERMITTED_PARAMS = [
    :top_msg, :success_msg, :show_phone, :show_instructions_from_customer, :active,
    :customer_confirm_email_tpl, :customer_confirm_email_tpl_enabled,
    :reserve_product_modal_tpl, :reserve_product_modal_tpl_enabled,
    :choose_location_modal_tpl, :choose_location_modal_tpl_enabled,
    :reserve_modal_faq_tpl, :reserve_modal_faq_tpl_enabled,
    :reserve_product_btn_tpl, :reserve_product_btn_selector, :reserve_product_btn_action
  ]

  def currency_template
    shopify_settings[:money_format].presence || '${{amount}}'
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
    if customer_confirm_email_tpl.present? && customer_confirm_email_tpl.gsub(/\s+/, "") == Store::customer_confirm_email_tpl.gsub(/\s+/, "")
      self.customer_confirm_email_tpl = nil
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

  def api
    @api ||= CachedShopifyAPI.new(self)
  end

  def shopify_settings
    api.shop.attributes.with_indifferent_access
  end

  def with_shopify_session
    ShopifyAPI::Session.temp(shopify_domain, shopify_token) { yield(self) }
  end


  def shopify_link
    "<a href='https://#{shopify_domain}'>#{name}</a>"
  end

  ##
  # Ensure that the scripts we are injecting have validity with our active state
  # This method is exclusively used by the stores/save_settings controller
  # This method can modify the errors array
  # @return [Bool] If we pass validation or not
  def validate_active_and_save!
    (!active_changed? || active_validation!) && save
  end

  ##
  # Ask Shopify for each location attached to this store
  # Ask Shopify for the store's email as well, to use as the default email for each location
  # Convert them into a Location instance, and save it to this store if it has an address
  def populate_locations_from_api!
    store_email = shopify_settings[:email].to_s

    api.locations.each do |shopify_loc|
      loc = Location.new_from_shopify(shopify_loc)
      loc.update(store_id: id, email: store_email) if loc.address.present?
    end
  end

  ##
  # @deprecated Temporary code and can be removed by May 31, 2019
  def fix_locations!
    new_locations = api.locations.map do |shopify_loc|
      Location.new_from_shopify(shopify_loc)
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

  ##
  # @return [Text] - The template we want to use for emails for this store
  def customer_confirm_email_tpl_in_use
    customer_confirm_email_tpl.presence || Store.default_customer_confirm_email_tpl
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
  def choose_location_modal_tpl_in_use
    if choose_location_modal_tpl_enabled?
      choose_location_modal_tpl.to_s
    else
      self.class.default_choose_location_modal_tpl
    end
  end

  ##
  # @return [Hash] - liquid params used by JS email previewer
  def frontend_tpl_vars
    {
      locations: locations.to_a,
      cdn_url: ENV['CDN_BASE_PATH'],
      settings: self
    }
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

  ##
  # Ensure our Shopify ScriptTags:
  # If we are active, then our scripttags must be in the api
  # If we are not active, then our scripttags must not be in the api
  # Modify the errors array and flip our active state if we have issues with the APIs.
  # @return [Bool] If we pass validation or not
  def active_validation!
    script_tags = ShopifyAPI::ScriptTag.all

    if active? && script_tags.empty?
      ShopifyAPI::ScriptTag.create({event:'onload', src: "#{ENV['CDN_JS_BASE_PATH']}reserveinstore.js"})
    elsif !active && script_tags.present?
      ShopifyAPI::ScriptTag.delete(ShopifyAPI::ScriptTag.first.id)
    end

    true
  rescue StandardError => e
    ForcedLogger.error(e, store: id)
    errors.add(:active, "Issue modifying your storefront. Try again / contact support so we can help you.")
    self.active = false

    false
  end

end
