class AddFixedPriceToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :fixed_price, :float
  end
end
