class AddZipToLocations < ActiveRecord::Migration[5.2]
  def change
    add_column :locations, :zip, :string
  end
end
