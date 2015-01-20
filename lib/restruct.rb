require 'redic'
require 'class_config'
require 'forwardable'

require_relative 'restruct/version'
require_relative 'restruct/structure'
require_relative 'restruct/key'
require_relative 'restruct/array'
require_relative 'restruct/marshal_array'
require_relative 'restruct/hash'

module Restruct

  extend ClassConfig

  attr_config :redis, Redic.new
  attr_config :key_separator, ':'
  attr_config :key_generator, ->() { SecureRandom.uuid }

  def self.generate_key
    Key.new key_generator.call
  end

end