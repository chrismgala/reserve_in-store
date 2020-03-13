class AddSenderOptionsToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :customer_confirmation_sender_name, :string
    add_column :stores, :location_notification_sender_name, :string
  end
end
