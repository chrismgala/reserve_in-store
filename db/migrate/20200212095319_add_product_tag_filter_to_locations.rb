class AddProductTagFilterToLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :product_tag_filter, :string
  end
end
