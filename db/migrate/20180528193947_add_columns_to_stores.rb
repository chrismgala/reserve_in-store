class AddColumnsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :platform_store_id, :string
    add_column :stores, :public_key, :string
    add_column :stores, :secret_key, :string
    add_column :stores, :name, :string
    add_column :stores, :top_msg, :text
    add_column :stores, :success_msg, :text
    add_column :stores, :email_template, :text
    add_column :stores, :show_phone, :boolean, default: true
    add_column :stores, :show_comments, :boolean, default: true
  end
end
