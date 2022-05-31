class AddCheckoutSuccessMessageTplToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :checkout_success_message_tpl, :string
  end
end
