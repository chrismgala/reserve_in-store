class AddIsUnFulfilledToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :is_unfulfilled, :boolean
  end
end
