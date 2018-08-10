class ChangeReservationColumnName < ActiveRecord::Migration[5.2]
  def change
    rename_column :reservations, :comments, :instructions_from_customer
    rename_column :stores, :show_comments, :show_instructions_from_customer
  end
end
