class CheckoutController < ApplicationController
  before_action :set_cart

  def new
    unless @cart.has_items?
      redirect_to cart_path, alert: "Your cart is empty"
      nil
    end
  end

  def shipping
    unless @cart.has_items?
      redirect_to cart_path, alert: "Your cart is empty"
      nil
    end
  end

  def payment
    unless @cart.has_items?
      redirect_to cart_path, alert: "Your cart is empty"
      return
    end

    if params[:shipping].present?
      @cart.update(
        shipping_name: params[:shipping][:name],
        shipping_address: params[:shipping][:address],
        shipping_city: params[:shipping][:city],
        shipping_state: params[:shipping][:state],
        shipping_zip: params[:shipping][:zip],
        shipping_country: params[:shipping][:country]
      )
    end

    unless @cart.shipping_address_complete?
      redirect_to checkout_shipping_path, alert: "Please complete shipping information"
      nil
    end
  end

  def process_checkout
    checkout_processor = Checkout::Processor.new(@cart)

    result = checkout_processor.process(
      shipping_params: shipping_address_params,
      payment_params: payment_details_params
    )

    if result.success?
      Current.user.orders.create!(status: "cart")

      redirect_to checkout_confirmation_path(order_id: result.order.id),
                  notice: "Order placed successfully!"
    else
      flash.now[:alert] = result.message
      render :payment, status: :unprocessable_entity
    end
  rescue Checkout::CheckoutError => e
    flash.now[:alert] = e.message
    render :payment, status: :unprocessable_entity
  end

  def confirmation
    @order = Current.user.orders.completed.find_by(id: params[:order_id])

    unless @order
      redirect_to root_path, alert: "Order not found"
    end
  end

  private

  def set_cart
    @cart = Current.user.current_cart
  end

  def shipping_address_params
    params.require(:shipping).permit(
      :name,
      :address,
      :city,
      :state,
      :zip,
      :country
    )
  end

  def payment_details_params
    params.require(:payment).permit(
      :card_number,
      :expiry_month,
      :expiry_year,
      :cvv,
      :cardholder_name
    )
  end
end
