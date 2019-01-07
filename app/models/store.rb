class Store < ActiveRecord::Base
  include ShopifyApp::SessionStorage
  has_many :locations, dependent: :destroy
  has_many :reservations

  before_create :generate_keys
  before_save :nil_default_templates

  PERMITTED_PARAMS = [:top_msg, :success_msg, :email_template, :show_phone, :show_instructions_from_customer, :active]

  ##
  # @return [Text] - default, un-rendered email template
  def self.default_email_template
    Rails.cache.fetch("default_email_template", expires_in: Rails.env.production? ? 1.year : 1.second) do
      ApplicationController.new.render_to_string(partial: 'customer_mailer/email_template')
    end
  end

  ##
  # @return [Hash] - liquid params used by JS email previewer
  def preview_email_liquid_params
    {'customer_first_name' => "John",
     'customer_last_name' => "Doe",
     'product_link' => "<a href=#>Apple (Red)</a>",
     'location_name' => "Store 3",
     'location_address' => "1234 Test St.",
     'location_city' => "City",
     'location_state' => "State",
     'location_country' => "Country",
     'store_link' => "<a href=#>Store 3</a>",
     "reservation_time" => "Monday at 5:30pm"}.to_json.html_safe
  end

  ##
  # @return [Text] - The template we want to use for emails for this store
  def email_template_in_use
    email_template || Store::default_email_template
  end

  ##
  # Swap out our template to be nil if they are defaulted
  def nil_default_templates
    if email_template.present? && email_template.gsub(/\s+/, "") == Store::default_email_template.gsub(/\s+/, "")
      self.email_template = nil
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
    money_format.gsub('{{amount}}', money_amount)
  end

  ##
  # Get store's money format from cache, hit Shopify Api if cache is missing
  # @return [String] Money format in the form of "${{amount}}"
  def money_format
    shopify_settings['money_format']
  end

  def shopify_settings
    Rails.cache.fetch("stores/#{id}/shopify_settings", expires_in: 1.week) do
      ShopifyAPI::Session.temp(shopify_domain, shopify_token) {
        ShopifyAPI::Shop.current.attributes
      }
    end.with_indifferent_access
  end

  def with_shopify_session
    ShopifyAPI::Session.temp(shopify_domain, shopify_token) { yield(self) }
  end


  def shopify_link
    "<a href='https://#{shopify_domain}'>#{name}</a>"
  end

  ##
  # Ensure that the scripts we are injecting has validity with our active state
  # This method is exclusively used by the stores/save_settings controller
  # This method can modify the errors array
  def validate_active_and_save!
    active_validation! if active_changed?
    self.save
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
  def active_validation!
    begin
      script_tags = ShopifyAPI::ScriptTag.all
      if active && script_tags.empty?
        ShopifyAPI::ScriptTag.create({event:'onload', src: "#{ENV['CDN_JS_BASE_PATH']}reserveinstore.js"})
      elsif !active && script_tags.present?
        ShopifyAPI::ScriptTag.delete(ShopifyAPI::ScriptTag.first.id)
      end
    rescue StandardError => e
      ForcedLogger.error("Failed ScriptTag update for store id #{id}", store: id)
      errors.add(:active, "Issue modifying your storefront. Try again / contact support so we can help you.")
      self.active = !active
    end
  end

end
