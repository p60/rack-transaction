require 'spec_helper'

describe Rack::Transaction do
  let(:inner){ mock }
  let(:env){ {'field' => 'variable'} }
  let(:table_name){ :rack }
  let(:dataset){ connection[table_name] }
  let(:error){ Sequel::Rollback }

  subject do
    context = self
    Rack::Transaction.new inner do
      provided_by context.connection
      rollback_with context.error
    end
  end

  before do
    connection.create_table table_name do
      column :name, String, null: false
    end
  end

  after do
    connection.drop_table table_name
    inner.verify
  end

  def expect_call(status)
    inner.expect :call, [status, {}, []] do |(environment), *args|
      dataset.insert(name: 'insert') if args.empty? && environment == env
    end
  end

  it 'wont rollback when ok' do
    expect_call 200
    result = subject.call env
    result.must_equal [200, {}, []]
    dataset.wont_be :empty?
  end

  it 'wont roll back on redirect' do
    expect_call 301
    result = subject.call env
    result.must_equal [301, {}, []]
    dataset.wont_be :empty?
  end

  it 'rolls back on error' do
    expect_call 400
    result = subject.call env
    result.must_equal [400, {}, []]
    dataset.must_be :empty?
  end

  it 'rolls back on string rollback' do
    expect_call 400
    subject.config.rollback_with("Sequel::Rollback")
    result = subject.call env
    result.must_equal [400, {}, []]
    dataset.must_be :empty?
  end

  it 'ensures valid configuration' do
    middleware = Rack::Transaction.new inner
    proc { middleware.call env }.must_raise Rack::Transaction::Configuration::Invalid
  end
end
