module ReservationsHelper
  include SortableHelper

  ##
  # @param [Reservation] reservations reservations displayed on current page
  # @return [ShopifyAPI::Product|NilClass] nil if no available products, otherwise a collecFtion of Shopify products
  def related_products(reservations)
    product_ids = reservations.map {|r| r.platform_product_id}.uniq.reject {|id| non_numeric_string(id)}
    @related_products = shopify_products({ids: product_ids.join(','), limit: 250})
  end

  ##
  # @param [Hash] shopify_search_params, including ids, limit, etc
  # @return [ShopifyAPI::Product|NilClass] nil if no available products, otherwise a collection of Shopify products
  def shopify_products(shopify_search_params)
    ForcedLogger.log("Shopify Api fetch products " + shopify_search_params.to_s, store: @current_store.try(:id))
    ShopifyAPI::Product.where(shopify_search_params)
  rescue StandardError => e
    ForcedLogger.error("Failed to load Shopify products where #{shopify_search_params}, #{e}", sentry: true, store: @current_store.try(:id))
    nil
  end

  ##
  # @return [Boolean] true if string contains non-numeric characters, otherwise returns false
  def non_numeric_string(string)
    string.scan(/\D/).any?
  end
end
