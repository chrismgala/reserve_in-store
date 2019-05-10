class ShopUpdateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    store = Store.find_by(shopify_domain: shop_domain)

    return if store.blank?

    ForcedLogger.log("ShopUpdateJob called.", store: store.id)

    store.cached_api.clear_shop_cache
  end
end
