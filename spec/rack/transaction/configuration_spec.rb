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
    it 'sets rollback_error' do
      rollback_error = Object
      result = subject.rollback_with rollback_error
      result.must_equal subject
      subject.rollback_error.must_equal rollback_error
    end
  end

  describe "#validate_with" do
    it 'sets response_validation' do
      callable = nil
      result = subject.validate_with {|response, env| callable = true}
      result.must_equal subject

      subject.response_validation.call
      callable.must_equal true
    end

    it 'raises when response_validation does not respond to :call' do
      proc {
        subject.validate_with
      }.must_raise Rack::Transaction::Configuration::InvalidResponseValidation
    end
  end

  describe '#validate!' do
    let(:provider){ Rack::Transaction::Configuration }
    subject { Rack::Transaction::Configuration }

    it 'raises when provider not configured' do
      config = subject.new do
        rollback_with(Object)
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
        rollback_with(Object)
      end
      config.validate!
    end
  end

  describe 'with defaults' do
    it 'accepts env' do
      subject.accepts?(env).must_equal true
    end

    %w{DELETE POST PUT}.each do |method|
      it "accepts env of #{method} request" do
        env['REQUEST_METHOD'] = method
        subject.accepts?(env).must_equal true
      end
    end

    %w{GET HEAD OPTIONS}.each do |method|
      it "wont accept env of #{method} request" do
        env['REQUEST_METHOD'] = method
        subject.accepts?(env).must_equal false
      end
    end
  end

  describe 'with inclusion' do
    let(:env){ {'REQUEST_METHOD' => 'GET'} }

    it 'returns self' do
      result = subject.include(&:get?)
      result.must_equal subject
    end

    it 'accepts env' do
      subject.include(&:get?)
      subject.accepts?(env).must_equal true
    end
  end

  describe 'with exclusion' do
    let(:env){ {'REQUEST_METHOD' => 'POST'} }

    it 'returns self' do
      result = subject.exclude(&:post?)
      result.must_equal subject
    end

    it 'wont accept excluded env' do
      subject.exclude(&:post?)
      subject.accepts?(env).must_equal false
    end
  end
end
