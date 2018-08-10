class ChangeStoreTopMessageDefault < ActiveRecord::Migration[5.2]
  def up
    change_column :stores, :top_msg, :text, default: "Fill out the form below and we'll reserve the product at the location you specify."
  end
  def down
    change_column :stores, :top_msg, :text
  end
end
