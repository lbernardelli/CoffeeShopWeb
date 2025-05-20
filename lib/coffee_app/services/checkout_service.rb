module CoffeeApp
  module Services
    class CheckoutService
      attr_reader :order, :payment_gateway

      # @param order [Order] The order to process
      # @param payment_gateway [CoffeeApp::Payment::PaymentGateway] Payment gateway implementation
      def initialize(order, payment_gateway: default_payment_gateway)
        @order = order
        @payment_gateway = payment_gateway
        validate_dependencies!
      end

      # @param shipping_params [Hash] Shipping address information
      # @param payment_params [Hash] Payment method information
      # @return [CheckoutResult] Result of the checkout attempt
      def process(shipping_params:, payment_params:)
        validate_order!
        update_shipping_info(shipping_params)
        payment_result = process_payment(payment_params)

        if payment_result.success?
          complete_order(payment_result)
        else
          rollback_order(payment_result)
        end
      rescue StandardError => e
        raise e if e.is_a?(CheckoutError)
        handle_error(e)
      end

      private

      def validate_dependencies!
        raise ArgumentError, "Order cannot be nil" if order.nil?
        raise ArgumentError, "Payment gateway cannot be nil" if payment_gateway.nil?

        required_methods = [:charge, :refund, :available?]
        missing_methods = required_methods.reject { |method| payment_gateway.respond_to?(method) }

        unless missing_methods.empty?
          raise ArgumentError, "Payment gateway must implement PaymentGateway interface (missing: #{missing_methods.join(', ')})"
        end
      end

      def validate_order!
        raise CheckoutError, "Order must have items" unless order.has_items?
        raise CheckoutError, "Payment gateway is not available" unless payment_gateway.available?
      end

      def update_shipping_info(shipping_params)
        order.assign_attributes(
          shipping_name: shipping_params[:name],
          shipping_address: shipping_params[:address],
          shipping_city: shipping_params[:city],
          shipping_state: shipping_params[:state],
          shipping_zip: shipping_params[:zip],
          shipping_country: shipping_params[:country] || "US"
        )

        unless order.shipping_address_complete?
          raise CheckoutError, "Incomplete shipping information"
        end

        order.save!
      end

      def process_payment(payment_params)
        payment_gateway.charge(
          amount: order.grand_total,
          payment_details: {
            card_number: payment_params[:card_number],
            expiry_month: payment_params[:expiry_month],
            expiry_year: payment_params[:expiry_year],
            cvv: payment_params[:cvv],
            cardholder_name: payment_params[:cardholder_name]
          },
          metadata: {
            order_id: order.id,
            user_id: order.user_id,
            items_count: order.order_items.count
          }
        )
      end

      def complete_order(payment_result)
        order.update!(
          status: "completed",
          payment_method: "credit_card",
          payment_transaction_id: payment_result.transaction_id
        )

        CheckoutResult.new(
          success: true,
          order: order,
          message: "Order completed successfully",
          payment_result: payment_result
        )
      end

      def rollback_order(payment_result)
        CheckoutResult.new(
          success: false,
          order: order,
          message: payment_result.message || "Payment failed",
          payment_result: payment_result
        )
      end

      def handle_error(error)
        CheckoutResult.new(
          success: false,
          order: order,
          message: error.message,
          payment_result: nil
        )
      end

      def default_payment_gateway
        CoffeeApp::Payment::Adapters::MockPaymentGateway.new
      end
    end

    class CheckoutResult
      attr_reader :success, :order, :message, :payment_result

      def initialize(success:, order:, message:, payment_result:)
        @success = success
        @order = order
        @message = message
        @payment_result = payment_result
        freeze
      end

      def success?
        @success == true
      end

      def failure?
        !success?
      end
    end

    class CheckoutError < StandardError; end
  end
end
