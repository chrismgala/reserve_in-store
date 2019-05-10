class InventoryFetcher
  attr_accessor :store, :product_id, :variant_id
  def initialize(store, product_id)
    @store = store
    @product_id = product_id
  end

  def inventory
    store.with_shopify_session do
      # Get Product
      product = store.api.product(product_id)

      return {} if product.blank?

      variant_map = product.variants.to_a.map{ |v| [v.inventory_item_id.to_s, v.id.to_s] }.to_h

      inventory_item_ids = variant_map.keys.join(",")

      return {} if inventory_item_ids.blank?

      # Get InventorLevel
      inventory_levels = store.api.inventory_levels(inventory_item_ids: inventory_item_ids)

      result_map = {}

      inventory_levels.each do |il|
        variant_id = variant_map[il.inventory_item_id.to_s]
        result_map[variant_id] ||= {}
        result_map[variant_id][il.location_id.to_s] = il.available.to_i
      end

      result_map
    end
  end

  def levels
    cache_key = "stores/#{store.id}/inventory_fetcher/product-#{product_id}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      stock_levels = inventory.to_h

      stock_levels.keys.map do |variant_id|
        new_levels = stock_levels[variant_id].keys.map do |platform_location_id|
          inventory_caption = if stock_levels[variant_id][platform_location_id] > 15
                                'in_stock'
                              elsif stock_levels[variant_id][platform_location_id] > 0
                                'low_stock'
                              else
                                'out_of_stock'
                              end
          [platform_location_id, inventory_caption]
        end.to_h
        [variant_id, new_levels]
      end.to_h
    end
  end

end
