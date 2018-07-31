class AppUninstalledJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    Store.find_by(shopify_domain: shop_domain).destroy!
  end
end
