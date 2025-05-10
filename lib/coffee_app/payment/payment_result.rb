module CoffeeApp
  module Payment
    class PaymentResult
      attr_reader :success, :transaction_id, :message, :metadata

      def initialize(success:, transaction_id: nil, message: nil, metadata: {})
        @success = success
        @transaction_id = transaction_id
        @message = message
        @metadata = metadata
        freeze
      end

      def success?
        @success == true
      end

      def failure?
        !success?
      end

      def error_message
        failure? ? @message : nil
      end
    end
  end
end
