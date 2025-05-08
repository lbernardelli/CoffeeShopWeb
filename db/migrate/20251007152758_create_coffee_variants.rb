class CreateCoffeeVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :coffee_variants do |t|
      t.references :coffee, null: false, foreign_key: true
      t.string :size, null: false
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :coffee_variants, [:coffee_id, :size], unique: true
  end
end
