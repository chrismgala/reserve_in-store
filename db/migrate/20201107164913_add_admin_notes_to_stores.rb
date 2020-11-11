class AddAdminNotesToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :admin_notes, :text
  end
end
