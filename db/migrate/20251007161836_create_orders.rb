class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'cart'
      t.decimal :total, precision: 10, scale: 2, default: 0, null: false

      t.timestamps
    end

    add_index :orders, [:user_id, :status]
  end
end
