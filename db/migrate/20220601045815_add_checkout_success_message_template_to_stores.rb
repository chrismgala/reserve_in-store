class AddCheckoutSuccessMessageTemplateToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :checkout_success_message_tpl, :string
    add_column :stores, :checkout_success_message_tpl_enabled, :boolean
  end
end
