class CartsController < ApplicationController
  before_action :set_cart

  def show
    @order_items = @cart.order_items.includes(coffee_variant: :coffee)
  end

  def add_item
    coffee_variant = CoffeeVariant.find(params[:coffee_variant_id])
    quantity = params[:quantity]&.to_i || 1

    @cart.add_item(coffee_variant, quantity)

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "#{coffee_variant.coffee.name} added to cart!" }
      format.turbo_stream
    end
  end

  def remove_item
    order_item = @cart.order_items.find(params[:order_item_id])
    order_item.destroy
    @cart.recalculate_total!

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Item removed from cart." }
      format.turbo_stream
    end
  end

  def update_quantity
    order_item = @cart.order_items.find(params[:order_item_id])
    new_quantity = params[:quantity].to_i

    if new_quantity > 0
      order_item.update(quantity: new_quantity)
      @cart.recalculate_total!
      message = "Quantity updated."
    else
      order_item.destroy
      @cart.recalculate_total!
      message = "Item removed from cart."
    end

    respond_to do |format|
      format.html { redirect_to cart_path, notice: message }
      format.turbo_stream
    end
  end

  private

  def set_cart
    @cart = Current.user.current_cart
  end
end
