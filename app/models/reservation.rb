class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :location

  validates :customer_name, :customer_email, presence: true
  validates_associated :store, :location
  validates :customer_email, format: /\A[^@\s]+@[^@\s]+\z/

  ##
  # @return [ShopifyAPI::Product|NilClass] nil if not product available, otherwise the shopify product model
  def shopify_product
    @shopify_product ||= ShopifyAPI::Product.find(platform_product_id)
  rescue => e
    Rails.logger.error(e)
    nil
  end

  ##
  # @return [ShopifyAPI::Variant|NilClass] nil if not variant available, otherwise the shopify variant model
  def shopify_variant
    @shopify_variant ||= ShopifyAPI::Variant.find(platform_variant_id)
  rescue => e
    Rails.logger.error(e)
    nil
  end

  def customer_first_name
    customer_name.to_s.split(' ').first
  end

  ##
  # Save the reservation, and send confirmation email to the customer and the store owner
  #
  # @return [Boolean] save result
  def save_and_email
    return false unless save
    ShopifyAPI::Session.temp(store.shopify_domain, store.shopify_token) {
      @product = shopify_product
      @variant = shopify_variant
    }
    CustomerMailer.reserve_confirmation(store, self, @product, @variant).deliver
    LocationMailer.new_reservation(store, self, @product, @variant).deliver
    true
  end
end
