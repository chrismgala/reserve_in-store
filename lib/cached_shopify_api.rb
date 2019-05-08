class CachedShopifyAPI
  attr_accessor :store
  def initialize(store)
    @store = store
  end

  def product(id)
    cache_key = "stores/#{store.id}/cached_shopify_api/product-#{id}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      store.with_shopify_session do
        ShopifyAPI::Product.find(id)
      end
    end
  end


  def inventory_levels(params = {})
    params = clean_list_params(params)
    cache_key = "stores/#{store.id}/cached_shopify_api/inventory_levels/#{params.to_param}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      store.with_shopify_session do
        ShopifyAPI::InventoryLevel.where(params).to_a
      end
    end
  end

  def locations(params = {})
    params = clean_list_params(params)
    cache_key = "stores/#{store.id}/cached_shopify_api/locations/#{params.to_param}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      store.with_shopify_session do
        ShopifyAPI::Location.where(params).to_a
      end
    end
  end

  def shop
    cache_key = "stores/#{store.id}/cached_shopify_api/shop"
    Rails.cache.fetch(cache_key, expires_in: 1.week) do
      store.with_shopify_session do
        ShopifyAPI::Shop.current
      end
    end
  end

  private

  def clean_list_params(params)
    { limit: 250 }.merge(params).stringify_keys.sort_by { |key, val| key }.to_h
  end
end
