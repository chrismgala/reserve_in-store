class AddStockStatusFieldsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :stock_status_tpl, :text
    add_column :stores, :stock_status_tpl_enabled, :boolean, default: false
    add_column :stores, :stock_status_selector, :string
    add_column :stores, :stock_status_action, :string, default: 'auto'
    add_column :stores, :stock_status_behavior_when_stock_unknown, :string, default: 'show'
    add_column :stores, :stock_status_behavior_when_no_location_selected, :string, default: 'use_nearby'
    add_column :stores, :stock_status_behavior_when_no_nearby_locations_and_no_location, :string, default: 'hide'
  end
end
