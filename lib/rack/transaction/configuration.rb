module Rack
  class Transaction
    class Configuration
      class Invalid < StandardError; end
      class InvalidProvider < StandardError; end
      class InvalidResponseValidation < StandardError; end

      attr_reader :provider, :rollback_error, :response_validation

      def initialize(&block)
        @includers = []
        @excluders = []
        with_defaults

        instance_eval(&block) if block_given?
      end

      def provided_by(value)
        raise InvalidProvider, 'Provider must respond to transaction' unless value.respond_to?(:transaction)
        @provider = value
        self
      end

      def rollback_with(value)
        @rollback_error = value
        self
      end

      def validate_with(&validation)
        raise InvalidResponseValidation, 'Response validation must respond to call' unless validation.respond_to?(:call)
        @response_validation = validation
        self
      end

      def validate!
        missing = []
        missing << 'provider' unless provider
        missing << 'rollback_error' unless rollback_error
        raise Invalid, "Missing #{missing.join ' & '}" if missing.any?
      end

      def include(&block)
        @includers << block
        self
      end

      def exclude(&block)
        @excluders << block
        self
      end

      def accepts?(env)
        request = Request.new env
        @excluders.all?{|x| !x.call(request)} || @includers.any?{|x| x.call(request)}
      end

      private

      def with_defaults
        exclude(&:get?)
        exclude(&:head?)
        exclude(&:options?)
      end
    end
  end
end
