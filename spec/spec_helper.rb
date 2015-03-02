require 'bundler/setup'
Bundler.require :development

$:.unshift File.expand_path('../../lib', __FILE__)
require 'minitest/pride'
require 'minitest/autorun'
require 'rack/transaction'

class Minitest::Spec
  def mock
    Minitest::Mock.new
  end

  def connection
    @connection ||= Sequel.connect 'sqlite:///'
  end
end
