require 'spec_helper'

describe Rack::Transaction::Configuration do
  let(:env){ {} }
  subject { Rack::Transaction::Configuration.new }

  describe "#provided_by" do
    it 'sets provider' do
      provider = Class.new { def self.transaction; end }
      result = subject.provided_by provider
      result.must_equal subject
      subject.provider.must_equal provider
    end

    it 'raises when provider does not respond to :transaction' do
      proc {
        subject.provided_by Object
      }.must_raise Rack::Transaction::Configuration::InvalidProvider
    end
  end

  describe "#rollback_with" do
    it 'sets rollback_error StandardError' do
      rollback_error = StandardError
      result = subject.rollback_with rollback_error
      result.must_equal subject
      subject.rollback_error.must_equal rollback_error
    end

    it 'sets rollback_error StandardError subclass' do
      rollback_error = RuntimeError
      result = subject.rollback_with rollback_error
      result.must_equal subject
      subject.rollback_error.must_equal rollback_error
    end

    it 'sets rollback_error with String' do
      rollback_error = 'RuntimeError'
      result = subject.rollback_with rollback_error
      result.must_equal subject
      subject.rollback_error.must_equal rollback_error
    end

    it 'raises when rollback_error not String or StandardError' do
      proc {
        subject.rollback_with Object.new
      }.must_raise Rack::Transaction::Configuration::InvalidRollbackError
    end
  end

  describe "#ensure_success_with" do
    it 'sets success_validation' do
      callable = nil
      result = subject.ensure_success_with {|response, env| callable = true}
      result.must_equal subject

      subject.success_validation.call
      callable.must_equal true
    end

    it 'raises when success_validation does not respond to :call' do
      proc {
        subject.ensure_success_with
      }.must_raise Rack::Transaction::Configuration::InvalidResponseValidation
    end
  end

  describe '#validate!' do
    let(:provider){ Rack::Transaction::Configuration }
    subject { Rack::Transaction::Configuration }

    it 'raises when provider not configured' do
      config = subject.new do
        rollback_with(StandardError)
      end
      proc { config.validate! }.must_raise Rack::Transaction::Configuration::Invalid
    end

    it 'raises when rollback_error not configured' do
      config = subject.new do
        provided_by(Class.new { def self.transaction; end })
      end
      proc { config.validate! }.must_raise Rack::Transaction::Configuration::Invalid
    end

    it 'wont raise when valid' do
      config = subject.new do
        provided_by(Class.new { def self.transaction; end })
        rollback_with(StandardError)
      end
      config.validate!
    end
  end

  describe '#successful?' do
    it 'is unsuccessful for a response with a client error' do
      response = Rack::Response.new [], 400, {}
      subject.successful?(response, {}).must_equal false
    end

    it 'is unsuccessful for a response with a server error' do
      response = Rack::Response.new [], 500, {}
      subject.successful?(response, {}).must_equal false
    end

    it 'is unsuccessful for a validation error' do
      validation_args = nil
      env = {}
      response = Rack::Response.new [], 200, {}

      subject.ensure_success_with { |*args| validation_args = args; false }
      subject.successful?(response, env).must_equal false


      validation_args.length.must_equal 2
      response_arg, env_arg = validation_args
      response_arg.must_equal response
      env_arg.must_equal env
    end

    it 'is successful' do
      response = Rack::Response.new [], 200, {}
      subject.successful?(response, {}).must_equal true
    end
  end

  describe 'with defaults' do
    let(:request){ Rack::Request.new env }

    it 'accepts request' do
      subject.accepts?(request).must_equal true
    end

    %w{DELETE POST PUT}.each do |method|
      it "accepts #{method} request" do
        env['REQUEST_METHOD'] = method
        subject.accepts?(request).must_equal true
      end
    end

    %w{GET HEAD OPTIONS}.each do |method|
      it "wont accept #{method} request" do
        env['REQUEST_METHOD'] = method
        subject.accepts?(request).must_equal false
      end
    end
  end

  describe 'with inclusion' do
    let(:env){ {'REQUEST_METHOD' => 'GET'} }
    let(:request){ Rack::Request.new env }

    it 'returns self' do
      result = subject.include(&:get?)
      result.must_equal subject
    end

    it 'accepts request' do
      subject.include(&:get?)
      subject.accepts?(request).must_equal true
    end
  end

  describe 'with exclusion' do
    let(:env){ {'REQUEST_METHOD' => 'POST'} }
    let(:request){ Rack::Request.new env }

    it 'returns self' do
      result = subject.exclude(&:post?)
      result.must_equal subject
    end

    it 'wont accept excluded request' do
      subject.exclude(&:post?)
      subject.accepts?(request).must_equal false
    end
  end
end
