class AddCheckoutFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_name, :string
    add_column :orders, :shipping_address, :text
    add_column :orders, :shipping_city, :string
    add_column :orders, :shipping_state, :string
    add_column :orders, :shipping_zip, :string
    add_column :orders, :shipping_country, :string
    add_column :orders, :payment_method, :string
    add_column :orders, :payment_transaction_id, :string
  end
end
