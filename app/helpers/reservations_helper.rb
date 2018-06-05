module ReservationsHelper
  ##
  # Retrieves a single Shopify product by its ID
  # Return false if it raised an error
  def product(id, params = {})
    begin
      ShopifyAPI::Product.find(id)
    rescue
      return false
    end
  end

  ##
  # Retrieves a single Shopify variant by its ID
  # Return false if it raised an error
  def variant(id)
    begin
      ShopifyAPI::Variant.find(id)
    rescue
      return false
    end
  end

end
