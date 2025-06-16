# frozen_string_literal: true
module Checkout
  class Result
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
end