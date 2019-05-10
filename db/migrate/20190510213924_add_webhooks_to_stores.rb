class AddWebhooksToStores < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :webhooks, :jsonb
  end
end
