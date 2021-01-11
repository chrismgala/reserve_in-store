class AddHideLocationSearchToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :hide_location_search, :boolean
  end
end
