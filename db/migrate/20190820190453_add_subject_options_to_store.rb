class AddSubjectOptionsToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :customer_confirmation_subject, :string
    add_column :stores, :location_notification_subject, :string
  end
end
