require 'coverage_helper'
require 'restruct'
require 'minitest/autorun'
require 'turn'
require 'pry-nav'

Turn.config do |c|
  c.format = :pretty
  c.natural = true
  c.ansi = true
end

class Minitest::Spec
  def connection
    Restruct.connection
  end

  after do
    connection.call('KEYS', Restruct::Id.new(:restruct)['*']).each { |k| connection.call 'DEL', k }
  end
end