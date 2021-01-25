class AddStatusNotificationsToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :reservation_fulfilled_send_notification, :boolean
    add_column :stores, :reservation_unfulfilled_send_notification, :boolean
  end
end
