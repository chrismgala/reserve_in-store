class AddStockThresholdToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :stock_threshold, :integer, default: 15
  end
end
