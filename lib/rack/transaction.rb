module Rack
  class Transaction
    VERSION = "0.1.0".freeze

    def initialize(inner, settings)
      @inner = inner
      @provider = settings.fetch(:provider)
      @rollback = settings.fetch(:rollback)
      @error = settings[:error]
    end

    def call(env)
      return @inner.call(env) unless use_transaction?(env)

      result = nil
      @provider.transaction do
        result = @inner.call(env)
        rollback if has_error?(env, *result)
      end
      result
    end

    private

    def has_error?(env, status, headers, body)
      response = Response.new body, status, headers
      response.client_error? || response.server_error? || (@error.respond_to?(:call) && @error.call(env))
    end

    def rollback
      klass = @rollback.is_a?(String) ? Object.const_get(@rollback) : @rollback
      raise klass
    end

    def use_transaction?(env)
      request = Request.new env
      !(request.get? || request.head? || request.options?)
    end
  end
end
