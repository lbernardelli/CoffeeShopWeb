class OrdersController < ApplicationController
  def index
    @orders = Current.user.orders.completed.includes(order_items: { coffee_variant: :coffee }).order(updated_at: :desc)
  end

  def show
    @order = Current.user.orders.completed.includes(order_items: { coffee_variant: :coffee }).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to orders_path, alert: "Order not found"
  end
end
