class AddMoreCustomFieldsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :reserve_product_btn_tpl_enabled, :boolean, default: false
    add_column :stores, :custom_css, :text
    add_column :stores, :custom_css_enabled, :boolean, default: false
  end
end
