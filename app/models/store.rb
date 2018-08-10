class Store < ActiveRecord::Base
  include ShopifyApp::SessionStorage
  has_many :locations, dependent: :destroy
  has_many :reservations

  before_create :generate_keys

  PERMITTED_PARAMS = [:top_msg, :success_msg, :email_template, :show_phone, :show_instructions_from_customer]

  ##
  # Display a product's price, check which currency the store is using, and render a string
  #
  # @param [String] money_amount "10.00"
  # @return [String] Price in the form of "$10.00"
  def price(money_amount)
    ShopifyAPI::Session.temp(shopify_domain, shopify_token) {
      ShopifyAPI::Shop.current.attributes['money_format'].gsub('{{amount}}', money_amount);
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

end
