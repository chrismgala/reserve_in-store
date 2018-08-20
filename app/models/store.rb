class Store < ActiveRecord::Base
  include ShopifyApp::SessionStorage
  has_many :locations, dependent: :destroy
  has_many :reservations

  before_create :generate_keys

  PERMITTED_PARAMS = [:top_msg, :success_msg, :email_template, :show_phone, :show_instructions_from_customer]

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
