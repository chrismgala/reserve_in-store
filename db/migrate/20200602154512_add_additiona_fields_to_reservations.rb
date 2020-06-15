class AddAdditionaFieldsToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :additional_fields, :jsonb, default: {}
  end
end
