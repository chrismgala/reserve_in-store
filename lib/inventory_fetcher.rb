class InventoryFetcher
  attr_accessor :store, :product_id, :variant_id, :mode
  def initialize(store, mode, product_id, use_cache: true)
    @store = store
    @product_id = product_id
    @use_cache = use_cache
    @mode = mode
  end

  def inventory
    store.with_shopify_session do
      # Get Product(s)
      if mode == "cart"
        #in this case, we will have received an array of product IDs
        product_list = store.api.products(ids: product_id.join(','))
      else
        product_list = store.api.products(ids: product_id)
      end

      return {} if product_list.blank?

      variant_map = {}
      product_map = {}
      product_list.each do |product|
        variants = product.variants.to_a
        variant_map.merge!(variants.map{ |v| [v.inventory_item_id.to_s, v.id.to_s] }.to_h)
        product_map.merge!(variants.map{ |v| [v.id.to_s, product.id.to_s] }.to_h)
      end


      inventory_item_ids = variant_map.keys.join(",")
      return {} if inventory_item_ids.blank?

      # Get Inventory Levels. We will make one API call even if we receive multiple products
      inventory_levels = store.api.inventory_levels(inventory_item_ids: inventory_item_ids)

      # concentrate inventory data based on variant ID
      inventory_map = {}

      inventory_levels.each do |il|
        variant_id = variant_map[il.inventory_item_id.to_s]
        inventory_map[variant_id] ||= {}
        inventory_map[variant_id][il.location_id.to_s] = il.available.to_i
      end

      result_map = {}

      if mode == "cart"
        # now concentrate inventory data based on product
        inventory_map.each do |im_key, im_value|
          variant_id = im_key.to_s
          p_id = product_map[variant_id]
          result_map[p_id] ||= {}
          result_map[p_id][variant_id] = im_value
        end
      else
        result_map = inventory_map
      end

      result_map
    end
  end

  def levels
    return load_levels unless @use_cache
    cache_key = "stores/#{store.id}/inventory_fetcher/product-#{product_id}"
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      load_levels
    end
  end

  def load_levels
    stock_levels = inventory.to_h

    if mode == "cart"
      stock_levels.keys.map do |product_id|
        product_stock_levels = stock_level_captions(stock_levels[product_id])
        [product_id, product_stock_levels]
      end.to_h
    else
      stock_level_captions(stock_levels)
    end
  end

  def stock_level_captions(stock_levels)
    stock_levels.keys.map do |variant_id|
      new_levels = stock_levels[variant_id].keys.map do |platform_location_id|
        inventory_caption = if stock_levels[variant_id][platform_location_id] > 15
                              'in_stock'
                            elsif stock_levels[variant_id][platform_location_id] > 0
                              'low_stock'
                            elsif stock_levels[variant_id][platform_location_id].nil?
                              'unknown_stock'
                            else
                              'out_of_stock'
                            end
        [platform_location_id, inventory_caption]
      end.to_h
      [variant_id, new_levels]
    end.to_h
  end

end
