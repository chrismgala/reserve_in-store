module ReservationsHelper
  ##
  # @param id [String] ID of the product we want to lookup
  # @return [ShopifyAPI::Product|FalseClass]  Return false if it raised an error, or the Product object if successful.
  def product(id)
    begin
      ShopifyAPI::Product.find(id)
    rescue
      Rails.logger.error 'Error! Retrieve Shopify product by ID failed'
      return false
    end
  end

  ##
  # @param id [String] ID of the variant we want to lookup
  # @return [ShopifyAPI::Variant|FalseClass]  Return false if it raised an error, or the Variant object if successful.
  def variant(id)
    begin
      ShopifyAPI::Variant.find(id)
    rescue
      Rails.logger.error 'Error! Retrieve Shopify variant by ID failed'
      return false
    end
  end

end
