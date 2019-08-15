class AddShowWhenOnlyAvailableOnlineToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :show_when_only_available_online, :boolean, default: true
  end
end
