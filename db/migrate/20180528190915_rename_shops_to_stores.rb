class RenameShopsToStores < ActiveRecord::Migration[5.2]
  def change
    rename_table :shops, :stores
  end
end
