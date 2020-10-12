class AddWebhooksEnabledToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :webhooks_enabled, :boolean
  end
end
