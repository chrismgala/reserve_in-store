class AddLineItemToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :line_item, :text
  end
end
