class AddCustomUnfulfilledTemplateToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :unfulfilled_reservation_custom_email_tpl, :text
    add_column :reservations, :unfulfilled_reservation_custom_email_tpl_enabled, :boolean
    add_column :reservations, :unfulfilled_reservation_email_sent, :boolean
  end
end
