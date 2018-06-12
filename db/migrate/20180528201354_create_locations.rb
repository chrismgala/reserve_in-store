class CreateLocations < ActiveRecord::Migration[5.2]
  def change
    create_table :locations do |t|
      t.belongs_to :store, index: true
      t.string :name, default: '', null: false
      t.string :address
      t.string :country
      t.string :state
      t.string :city
      t.string :email, default: '', null: false
      t.string :phone

      t.timestamps
    end
  end
end
