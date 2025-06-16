module Payment
  module Adapters
    # Simulates payment processing without external API calls
    class MockPaymentGateway < PaymentGateway
      APPROVED_CARD = "4111111111111111"
      DECLINED_CARD = "4000000000000002"
      ERROR_CARD = "4000000000000127"

      def charge(amount:, payment_details:, metadata: {})
        validate_amount!(amount)

        card_number = payment_details[:card_number]

        case card_number
        when APPROVED_CARD
          PaymentResult.new(
            success: true,
            transaction_id: generate_transaction_id,
            message: "Payment approved",
            metadata: {
              amount: amount,
              card_last_four: card_number.to_s.last(4),
              processed_at: Time.current
            }
          )
        when DECLINED_CARD
          PaymentResult.new(
            success: false,
            message: "Card declined - insufficient funds",
            metadata: { amount: amount }
          )
        when ERROR_CARD
          PaymentResult.new(
            success: false,
            message: "Payment gateway error - please try again",
            metadata: { amount: amount }
          )
        else
          PaymentResult.new(
            success: true,
            transaction_id: generate_transaction_id,
            message: "Payment approved",
            metadata: {
              amount: amount,
              card_last_four: card_number.to_s.last(4),
              processed_at: Time.current
            }
          )
        end
      end

      def refund(transaction_id:, amount:)
        validate_amount!(amount)

        PaymentResult.new(
          success: true,
          transaction_id: generate_transaction_id,
          message: "Refund processed",
          metadata: {
            original_transaction_id: transaction_id,
            amount: amount,
            processed_at: Time.current
          }
        )
      end

      def available?
        true
      end

      private

      def validate_amount!(amount)
        raise ArgumentError, "Amount must be positive" unless amount.to_d > 0
      end

      def generate_transaction_id
        "mock_#{SecureRandom.hex(10)}"
      end
    end
  end
end
