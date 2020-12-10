class AddShowStockStatusLabelsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :show_stock_status_labels, :jsonb, default: {
      in_reserve_modal_product_page_locations: ["in_stock", "low_stock", "no_stock", "stock_unknown"],
      in_reserve_modal_cart_page_locations: ["all_items_available", "x_items_available", "no_stock"],
      in_reserve_modal_cart_items: ["in_stock", "low_stock", "no_stock", "stock_unknown"],
      in_choose_location_modal_product_page: ["in_stock", "low_stock", "no_stock", "stock_unknown"]
    }
  end
end
