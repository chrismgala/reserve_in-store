class AddIndextoLocations < ActiveRecord::Migration[5.2]
  def change
    add_index :locations, [:store_id, :platform_location_id]
  end
end
