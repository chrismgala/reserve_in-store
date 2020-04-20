class AddConnectionErrorToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :last_connected_at, :datetime
    add_column :stores, :connection_error, :text
  end
end
