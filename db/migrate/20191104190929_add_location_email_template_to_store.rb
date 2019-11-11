class AddLocationEmailTemplateToStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :location_notification_email_tpl_enabled, :boolean, default: false
    add_column :stores, :location_notification_email_tpl, :text
  end
end
