# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rack/transaction/version', __FILE__)

Gem::Specification.new do |gem|
  gem.author        = 'vyrak.bunleang@gmail.com'
  gem.homepage      = 'https://github.com/p60/rack-transaction'
  gem.description   = 'Middleware for transactions'
  gem.summary       = 'Middleware for transactions'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'rack-transaction'
  gem.require_paths = ["lib"]
  gem.version       = Rack::Transaction::VERSION
end
