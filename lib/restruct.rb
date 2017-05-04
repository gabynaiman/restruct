require 'redic'
require 'class_config'
require 'forwardable'
require 'securerandom'

require_relative 'restruct/version'
require_relative 'restruct/errors'
require_relative 'restruct/structure'
require_relative 'restruct/id'
require_relative 'restruct/array'
require_relative 'restruct/set'
require_relative 'restruct/hash'
require_relative 'restruct/queue'
require_relative 'restruct/nested_hash'
require_relative 'restruct/marshalizable'
require_relative 'restruct/marshal_array'
require_relative 'restruct/marshal_set'
require_relative 'restruct/marshal_hash'
require_relative 'restruct/marshal_queue'
require_relative 'restruct/locker'
require_relative 'restruct/connection'


module Restruct

  extend ClassConfig

  attr_config :connection, Connection.new
  attr_config :id_separator, ':'
  attr_config :id_generator, ->() { Id.new(:restruct)[SecureRandom.uuid] }

  def self.generate_id
    id_generator.call
  end

end