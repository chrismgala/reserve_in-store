class AddDiscountCodeToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :discount_code, :text
  end
end
