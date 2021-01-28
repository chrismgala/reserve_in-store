class AddReservationStatusTemplateToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :unfulfilled_reservation_notification_email_tpl, :text
    add_column :stores, :unfulfilled_reservation_notification_email_tpl_enabled, :boolean
    add_column :stores, :unfulfilled_reservation_sender_name, :string
    add_column :stores, :unfulfilled_reservation_subject, :string
    add_column :stores, :fulfilled_reservation_notification_email_tpl, :text
    add_column :stores, :fulfilled_reservation_notification_email_tpl_enabled, :boolean
    add_column :stores, :fulfilled_reservation_sender_name, :string
    add_column :stores, :fulfilled_reservation_subject, :string
  end
end
