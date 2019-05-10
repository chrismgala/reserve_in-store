class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.integer :store_id
      t.string :name
      t.string :email
      t.string :phone

      t.timestamps

      t.index :store_id
      t.index :email
    end
  end
end
