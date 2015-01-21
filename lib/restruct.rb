require 'redic'
require 'class_config'
require 'forwardable'

require_relative 'restruct/version'
require_relative 'restruct/structure'
require_relative 'restruct/id'
require_relative 'restruct/array'
require_relative 'restruct/hash'
require_relative 'restruct/marshalizable'
require_relative 'restruct/marshal_array'
require_relative 'restruct/marshal_hash'

module Restruct

  extend ClassConfig

  attr_config :redis, Redic.new
  attr_config :id_separator, ':'
  attr_config :id_generator, ->() { SecureRandom.uuid }

  def self.generate_id
    Id.new id_generator.call
  end

end