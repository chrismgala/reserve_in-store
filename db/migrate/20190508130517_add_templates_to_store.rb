class AddTemplatesToStore < ActiveRecord::Migration[5.2]
  def change
    rename_column :stores, :email_template, :customer_confirm_email_tpl

    add_column :stores, :customer_confirm_email_tpl_enabled, :boolean, default: false

    add_column :stores, :reserve_product_modal_tpl_enabled, :boolean, default: false
    add_column :stores, :reserve_product_modal_tpl, :text

    add_column :stores, :choose_location_modal_tpl_enabled, :boolean, default: false
    add_column :stores, :choose_location_modal_tpl, :text

    add_column :stores, :reserve_product_btn_action, :string, default: 'auto'
    add_column :stores, :reserve_product_btn_selector, :string
    add_column :stores, :reserve_product_btn_tpl, :text

    add_column :stores, :reserve_modal_faq_tpl, :text
    add_column :stores, :reserve_modal_faq_tpl_enabled, :boolean, default: false
  end
end
