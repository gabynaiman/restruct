require 'coverage_helper'
require 'restruct'
require 'minitest/autorun'
require 'minitest/colorin'
require 'minitest/great_expectations'
require 'pry-nav'

class Minitest::Spec
  
  def connection
    Restruct.connection
  end

  after do
    connection.call('KEYS', Restruct::Id.new(:restruct)['*']).each { |k| connection.call 'DEL', k }
  end

end