class ChangeDefaultActiveForStores < ActiveRecord::Migration[5.2]
  def change
    change_column_default :stores, :active, false
  end
end
