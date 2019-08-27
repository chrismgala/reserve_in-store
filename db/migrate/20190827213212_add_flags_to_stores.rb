class AddFlagsToStores < ActiveRecord::Migration[5.2]

  def change
    add_column :stores, :flags, :jsonb
    add_column :users, :flags, :jsonb
  end
end
