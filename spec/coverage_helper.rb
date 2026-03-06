require 'simplecov'

if ENV['CI']
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
end

SimpleCov.start
