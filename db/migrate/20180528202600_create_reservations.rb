class CreateReservations < ActiveRecord::Migration[5.2]
  def change
    create_table :reservations do |t|
      t.belongs_to :store, index: true
      t.belongs_to :location, index: true
      t.string :customer_name, default: '', null: false
      t.string :customer_email, default: '', null: false
      t.string :customer_phone
      t.string :platform_product_id
      t.string :platform_variant_id
      t.text :comments
      t.boolean :fulfilled, default: false

      t.timestamps
    end
  end
end
