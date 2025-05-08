class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :coffee_variant, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :order_items, [:order_id, :coffee_variant_id], unique: true
  end
end
