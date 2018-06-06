class Reservation < ActiveRecord::Base
  belongs_to :store
  belongs_to :location

  validates :customer_name, :customer_email, presence: true
  validates_associated :store, :location

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
end
