class AddShowLocationSearchToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :show_location_search, :boolean
  end
end
