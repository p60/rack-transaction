# Rack::Transaction #

Rack::Transaction is a rack middleware that automatically wraps any incoming
requests with potential side effects (i.e. POST, PUT, or DELETE).

## Installation

Add this line to your Gemfile:

```ruby
gem 'rack-transaction', :require => 'rack/transaction'
```

or

```
gem install rack-transaction
```

## Usage

Add the following:

```ruby
use Rack::Transaction,
  provider: Sequel.connect('sqlite:///')  #required
  rollback: Sequel::Rollback              #required (it also accepts the string version of the constant)
```

Do note that `:rollback` will use the type specified to raise an error, which
in turn, causes the transaction to rollback. Depending on the `:provider`
providing the transaction, you may want to specify an error type provided by
the library being used to allow for more graceful error handling. For example,
Sequel has `Sequel::Rollback` and ActiveRecord has `ActiveRecord::Rollback`.

It also supports an optional error callback to check for errors in the
environment outside of the normal client or server errors. For example, Sinatra
sets `sinatra.error` on the `env` in the event of an error, so we'll probably
want to rollback.  We can check for this by specifying the `:error` setting.

```ruby
use Rack::Transaction,
  provider: Sequel.connect('sqlite:///')
  rollback: Sequel::Rollback
  error: ->(env){ env['sinatra.error'] }
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
