class CreateStores < ActiveRecord::Migration
  def change
    create_table :stores do |t|
      t.string :platform_store_id
      t.string :auth_token
      t.string :secret_key
      t.string :public_key
      t.string :name
      t.string :url
      t.text :top_msg
      t.text :success_msg
      t.boolean :show_phone
      t.boolean :show_comments

      t.timestamps
    end
  end
end
