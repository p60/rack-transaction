require 'rack/transaction/version'
require 'rack/transaction/configuration'

module Rack
  class Transaction
    attr_reader :config

    def initialize(inner, &block)
      @inner = inner
      @config = Configuration.new(&block)
    end

    def call(env)
      config.validate!

      return @inner.call(env) unless use_transaction?(env)

      result = nil
      config.provider.transaction do
        result = @inner.call(env)
        rollback unless successful?(env, *result)
      end
      result
    end

    private

    def use_transaction?(env)
      request = Request.new env
      config.accepts?(request)
    end

    def successful?(env, status, headers, body)
      response = Response.new body, status, headers
      config.successful?(env, response)
    end

    def rollback
      error = config.rollback_error
      klass = error.is_a?(String) ? Object.const_get(error) : error
      raise klass
    end
  end
end
