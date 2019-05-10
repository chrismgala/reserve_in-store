class LocationsUpdateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    store = Store.find_by(shopify_domain: shop_domain)
    return if store.blank?

    ForcedLogger.log("LocationsUpdateJob called.", store: store.id, platform_location: webhook[:id])

    location = store.locations.find_by(platform_location_id: webhook[:id])

    if location.blank?
      store.sync_locations!
    else
      location.load_from_shopify(webhook)
      location.save!
    end

    store.cached_api.clear_locations_cache
    store.cached_api.locations
  end
end
