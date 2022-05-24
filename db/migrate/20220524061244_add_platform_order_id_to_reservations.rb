class AddPlatformOrderIdToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :platform_order_id, :string
  end
end
