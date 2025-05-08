class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :roast_type
      t.string :origin
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :products, :name
    add_index :products, :roast_type
    add_index :products, :active
  end
end
