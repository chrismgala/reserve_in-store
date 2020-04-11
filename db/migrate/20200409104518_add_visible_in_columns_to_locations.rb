class AddVisibleInColumnsToLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :visible_in_cart, :boolean, default: true
    add_column :locations, :visible_in_product, :boolean, default: true
  end
end
