module Shopify
  class CachedApi < ::Shopify::Api

    def clear_cache!
      clear_locations_cache
      clear_shop_cache
    end

    def clear_product_cache(id)
      return if id.nil?
      Rails.cache.delete("stores/#{store.id}/cached_shopify_api/product-#{id}")
      Rails.cache.delete("stores/#{store.id}/inventory_fetcher/product-#{id}")
    end

    def clear_locations_cache
      Rails.cache.delete("stores/#{store.id}/cached_shopify_api/locations")
    end
    def clear_shop_cache
      Rails.cache.delete("stores/#{store.id}/cached_shopify_api/shop")
    end

    def product(id)
      return if id.nil?
      cache_key = "stores/#{store.id}/cached_shopify_api/product-#{id}"
      Rails.cache.fetch(cache_key, expires_in: 1.minutes) do
        super(id)
      end
    end

    def webhooks
      store.with_shopify_session do
        super
      end
    end

    def inventory_levels(params = {})
      params = clean_list_params(params)
      cache_key = "stores/#{store.id}/cached_shopify_api/inventory_levels/#{params.to_param}"
      Rails.cache.fetch(cache_key, expires_in: 1.minute) do
        super
      end
    end

    def locations
      cache_key = "stores/#{store.id}/cached_shopify_api/locations"
      Rails.cache.fetch(cache_key, expires_in: 1.day) do
        super
      end
    end

    def shop
      cache_key = "stores/#{store.id}/cached_shopify_api/shop"
      Rails.cache.fetch(cache_key, expires_in: 1.day) do
        ShopifyAPI::Shop.current
      end
    end

    private

    def clean_list_params(params)
      { limit: 250 }.merge(params).stringify_keys.sort_by { |key, val| key }.to_h
    end
  end
end
