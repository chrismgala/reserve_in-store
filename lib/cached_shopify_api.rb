class CachedShopifyAPI
  attr_accessor :store
  def initialize(store)
    @store = store
  end

  def product(id)
    cache_key = "stores/#{store.id}/cached_shopify_api/product-#{id}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      ShopifyAPI::Product.find(id)
    end
  end


  def inventory_levels(params)
    params = params.sort_by { |key, val| key }.to_h
    cache_key = "stores/#{store.id}/cached_shopify_api/inventory_levels/#{params.to_param}"
    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      ShopifyAPI::InventoryLevel.where(params).to_a
    end
  end
end
