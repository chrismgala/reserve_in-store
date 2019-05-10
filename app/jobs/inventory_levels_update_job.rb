class InventoryLevelsUpdateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    store = Store.find_by(shopify_domain: shop_domain)

    return if store.blank?

    store.cached_api.clear_product_cache(webhook[:id])
    store.cached_api.product(webhook[:id])

    # TODO - for now just logging, later we will need to refresh cache
    ForcedLogger.log("InventoryLevelsUpdateJob called with: #{webhook.inspect}.", store: store.id)
  end
end
