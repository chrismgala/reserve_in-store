class AddPlatformLocationIdToLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :platform_location_id, :string
  end
end
