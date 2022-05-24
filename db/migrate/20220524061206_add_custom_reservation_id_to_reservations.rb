class AddCustomReservationIdToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :custom_reservation_id, :string
  end
end
