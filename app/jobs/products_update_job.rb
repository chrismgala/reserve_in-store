class ProductsUpdateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    store = Store.find_by(shopify_domain: shop_domain)

    return if store.blank?

    # TODO - for now just logging, later we will need to refresh cache
    ForcedLogger.log("ProductsUpdateJob called with: #{webhook.inspect}.", store: store.id)
  end
end
