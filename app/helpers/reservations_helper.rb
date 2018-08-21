module ReservationsHelper
  ##
  # @param [Reservation] reservations reservations displayed on current page
  # @return [ShopifyAPI::Product|NilClass] nil if no available products, otherwise a collection of Shopify products
  def related_products(reservations)
    product_ids = reservations.map {|r| r.platform_product_id}.uniq.reject {|id| check_string(id)}
    @related_products = shopify_products({ids: product_ids.join(','), limit: 250})
  end

  ##
  # @param [Hash] params, including ids, limit, etc
  # @return [ShopifyAPI::Product|NilClass] nil if no available products, otherwise a collection of Shopify products
  def shopify_products(params)
    ForcedLogger.log("Shopify Api fetch products " + params.to_s)
    ShopifyAPI::Product.where(params)
  rescue => e
    ForcedLogger.error("Failed to load Shopify products where #{params}, #{e}", sentry: true)
    nil
  end

  ##
  # @return [Boolean] true if string contains non-numeric characters, otherwise returns false
  def check_string(string)
    string.scan(/\D/).any?
  end
end
