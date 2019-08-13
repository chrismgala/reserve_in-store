class ChangeDefaultStoreButtonSettingsToAlwaysShow < ActiveRecord::Migration[5.2]
  def change
    change_column_default :stores, :stock_status_behavior_when_no_location_selected, "unknown_stock_show_button"
    change_column_default :stores, :stock_status_behavior_when_no_nearby_locations_and_no_location, "show_first_available"
  end
end
