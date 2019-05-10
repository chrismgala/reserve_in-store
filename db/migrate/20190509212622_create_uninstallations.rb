class CreateUninstallations < ActiveRecord::Migration[5.2]
  def change
    create_table :uninstallations do |t|
      t.integer :store_id
      t.jsonb :data

      t.timestamps
    end
  end
end
