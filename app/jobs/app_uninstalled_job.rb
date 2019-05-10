class AppUninstalledJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    store = Store.find_by(shopify_domain: shop_domain)

    return if store.blank?

    Uninstallation.create_from_store!(store)

    store.destroy!
  end
end
