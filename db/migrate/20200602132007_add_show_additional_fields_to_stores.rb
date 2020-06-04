class AddShowAdditionalFieldsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :show_additional_fields, :boolean, default: false
  end
end
