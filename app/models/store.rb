class Store < ActiveRecord::Base
  include ShopifyApp::SessionStorage
  has_many :locations, dependent: :destroy
  has_many :reservations

  before_create :generate_keys
  before_save :nil_default_templates

  PERMITTED_PARAMS = [:top_msg, :success_msg, :email_template, :show_phone, :show_instructions_from_customer]

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
  # Return all products information associated with a store
  # @return [Array] empty array if no available products, otherwise an array of ShopifyAPI::Product
  def related_products
    product_ids = self.reservations.map {|r| r.platform_product_id}
    product_ids = product_ids.uniq.in_groups_of(250, false)
    @related_products = Array.new
    product_ids.each do |max_250_ids|
        @related_products += shopify_products({ids: max_250_ids.join(','), limit: 250}).to_a
    end
    @related_products
  end

  ##
  # @param [Hash] params, including ids, limit, etc
  # @return [ShopifyAPI::Product|NilClass] nil if no available products, otherwise a collection of Shopify products
  def shopify_products(params)
    puts "Shopify Api fetch products " + params.to_s
    ShopifyAPI::Product.where(params)
  rescue => e
    Rails.logger.error(e)
    nil
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
    Rails.cache.fetch("stores/#{id}/money_format", expires_in: 1.month) do
      ShopifyAPI::Session.temp(shopify_domain, shopify_token) {
        format = ShopifyAPI::Shop.current.attributes['money_format']
        puts " >>> `HIT SHOPIFY API (ShopifyAPI::Shop.current)"
        format
      }
    end
  end

  def shopify_link
    "<a href='https://#{shopify_domain}'>#{name}</a>"
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

end
