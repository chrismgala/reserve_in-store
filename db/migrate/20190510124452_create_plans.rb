class CreatePlans < ActiveRecord::Migration[5.2]
  def change
    create_table :plans do |t|
      t.float :price
      t.string :name
      t.jsonb :features
      t.jsonb :limits
      t.string :code
      t.integer :trial_days

      t.timestamps

      t.index :code
    end
  end
end
