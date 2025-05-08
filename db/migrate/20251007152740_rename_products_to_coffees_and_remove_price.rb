class RenameProductsToCoffeesAndRemovePrice < ActiveRecord::Migration[8.0]
  def change
    rename_table :products, :coffees
    remove_column :coffees, :price, :decimal
  end
end
