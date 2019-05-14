class AddCartDataToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :cart, :jsonb

    add_column :stores, :reserve_cart_btn_tpl, :text
    add_column :stores, :reserve_cart_btn_tpl_enabled, :boolean, default: false
    add_column :stores, :reserve_cart_btn_selector, :string
    add_column :stores, :reserve_cart_btn_action, :string, default: 'auto'

    rename_column :stores, :reserve_product_modal_tpl, :reserve_modal_tpl
    rename_column :stores, :reserve_product_modal_tpl_enabled, :reserve_modal_tpl_enabled
  end
end
