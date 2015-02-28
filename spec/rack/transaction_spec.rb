require 'spec_helper'
require 'rack/transaction'

describe Rack::Transaction do
  let(:inner){ mock }
  let(:env){ {'field' => 'variable'} }
  let(:table_name){ :rack }
  let(:dataset){ connection[table_name] }
  let(:rollback){ Sequel::Rollback }
  let(:settings){ {provider: connection, rollback: rollback} }

  subject { Rack::Transaction.new inner, settings }

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

  it 'rolls back on server error' do
    expect_call 500
    result = subject.call env
    result.must_equal [500, {}, []]
    dataset.must_be :empty?
  end

  it 'rolls back on client error' do
    expect_call 400
    result = subject.call env
    result.must_equal [400, {}, []]
    dataset.must_be :empty?
  end

  it 'rolls back on custom error callback' do
    args = nil
    settings[:error] = ->(*a){ args = a; true }
    expect_call 200
    result = subject.call env
    result.must_equal [200, {}, []]
    dataset.must_be :empty?
    args.must_equal [env]
  end

  it 'rolls back on string rollback' do
    settings[:rollback] = "Sequel::Rollback"
    expect_call 400
    result = subject.call env
    result.must_equal [400, {}, []]
    dataset.must_be :empty?
  end

  %w{ GET HEAD OPTIONS }.each do |method|
    # shouldn't be modifying anything on these types of requests; modifying for assertion purposes

    describe "on #{method} request" do
      before { env['REQUEST_METHOD'] = method }

      it 'wont rollback on custom error callback' do
        settings[:error] = ->{ true }
        expect_call 200
        subject.call env
        dataset.wont_be :empty?
      end

      it 'wont rollback on server error' do
        expect_call 500
        subject.call env
        dataset.wont_be :empty?
      end

      it 'wont rollback on client error' do
        expect_call 400
        subject.call env
        dataset.wont_be :empty?
      end
    end
  end
end
