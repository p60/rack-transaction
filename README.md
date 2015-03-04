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
config = Rack::Transaction::Configuration.new do
  provided_by Sequel.connect('sqlite:///')  #required
  rollback_with Sequel::Rollback            #required (it also accepts the string version of the constant)
end

use Rack::Transaction, config
```

or, with the shorthand form:

```ruby
use Rack::Transaction do
  provided_by Sequel.connect('sqlite:///')  #required
  rollback_with Sequel::Rollback            #required (it also accepts the string version of the constant)
end
```

Do note that `rollback_with` will use the type specified to raise an error,
which in turn, causes the transaction to rollback. Depending on the provider,
passed into `provided_by`, providing the transaction, you may want to specify
an error type provided by the library being used to allow for more graceful
error handling. For example, Sequel has `Sequel::Rollback` and ActiveRecord has
`ActiveRecord::Rollback`.

It also supports an optional callback to validate that an action was
successful, even if it wasn't recognized as a client or server error. For
example, Sinatra sets `sinatra.error` on the `env` in the event of an error, so
we'll probably want to rollback.  We can specify the validation callback with
`ensure_success_with`. The callback will have the `Rack::Response` and `env`
passed to it as arguments.

```ruby
use Rack::Transaction do
  provided_by Sequel.connect('sqlite:///')
  rollback_with Sequel::Rollback
  ensure_success_with { |response, env| env['sinatra.error'] }
```

### Configuration

By default, `Rack::Transaction` will wrap all requests except for request of
methods GET, HEAD, & OPTION. It also provides away to include or exclude
certain requests from participating in the transaction. This is done by passing
in a block to `include` or `exclude` to the configuration. The block can expect
a `Rack::Request` instance to be used to determine whether or not to include or
exclude said request. For example, you may want to wrap a GET request in a
transaction, because the action it routes to is handling the final leg of
OAauth authorization and saving the refresh token as well as other business
logic.

```ruby
use Rack::Transaction do
  // other config stuff

  include { |request| request.path =~ %r{/oauth/callback$}i }
  exclude { |request| request.path =~ %r{/search$}i }
end
```

Do note that includes take priority over any excludes specified.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
