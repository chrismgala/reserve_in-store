class CreateSubscriptions < ActiveRecord::Migration[5.2]
  def change
    create_table :subscriptions do |t|
      t.integer :store_id
      t.string :remote_id
      t.jsonb :plan_attributes
      t.jsonb :custom_attributes

      t.timestamps

      t.index :store_id
      t.index :remote_id
    end
  end
end
