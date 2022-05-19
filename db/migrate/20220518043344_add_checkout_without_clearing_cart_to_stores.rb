class AddCheckoutWithoutClearingCartToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :checkout_without_clearing_cart, :boolean
  end
end
