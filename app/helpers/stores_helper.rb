module StoresHelper
  def store_webhooks
    ["reservations/create", "reservations/fulfilled"]
  end

  def default_stock_status_labels
    {
      in_stock: "In Stock",
      low_stock: "Low Stock",
      no_stock: "No Stock",
      stock_unknown: "Stock Unknown"
    }
  end

  def default_stock_status_labels_cart_page
    {
      all_items_available: "All Items Available",
      x_items_available: "X items available",
      no_stock: "No Stock"
    }
  end

  def stock_status_where_to_show
    {
      in_reserve_modal_product_page_locations: "Reserve modal locations (product page)",
      in_reserve_modal_cart_page_locations: "Reserve modal locations (cart page)",
      in_reserve_modal_cart_items: "Reserved product or cart items",
      in_choose_location_modal_product_page: "Choose Location Modal (product page)"
    }
  end

  ##
  # Shopify does not allow us to edit theme due to which we need to provide manual installation footer js script.
  # Used in help article to manually copy and paste code.
  def footer_script_js_code
    StoreIntegrator.new(@current_store).footer_script_code
  end
end
