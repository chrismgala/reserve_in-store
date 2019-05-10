class ProductsCreateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    store = Store.find_by(shopify_domain: shop_domain)

    return if store.blank?

    store.api.clear_product_cache(webhook[:id])
    store.api.product(webhook[:id])

    # TODO - for now just logging, later we will need to refresh cache
    ForcedLogger.log("ProductsCreateJob called with: #{webhook.inspect}.", store: store.id)
  end
end
