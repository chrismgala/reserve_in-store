class ChangeStoreTopMessageDefault < ActiveRecord::Migration[5.2]
  def change
    change_column :stores, :top_msg, :text, default: "Fill out the form below and we'll reserve the product at the location you specify."
  end
end
