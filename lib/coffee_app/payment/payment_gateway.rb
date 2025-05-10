module CoffeeApp
  module Payment
    class PaymentGateway
      # Process a payment
      # @param amount [BigDecimal] The amount to charge
      # @param payment_details [Hash] Payment method details (card, token, etc)
      # @param metadata [Hash] Additional transaction metadata
      # @return [PaymentResult] Result of the payment attempt
      def charge(amount:, payment_details:, metadata: {})
        raise NotImplementedError, "#{self.class} must implement #charge"
      end

      # Refund a payment
      # @param transaction_id [String] The ID of the transaction to refund
      # @param amount [BigDecimal] The amount to refund
      # @return [PaymentResult] Result of the refund attempt
      def refund(transaction_id:, amount:)
        raise NotImplementedError, "#{self.class} must implement #refund"
      end

      # Check if a payment gateway is available
      # @return [Boolean] True if the gateway is ready to process payments
      def available?
        raise NotImplementedError, "#{self.class} must implement #available?"
      end
    end
  end
end
