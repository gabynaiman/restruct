require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  t.libs << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = false
end

task :console do
  require 'pry'
  require 'restruct'
  ARGV.clear
  Pry.start
end

task default: :spec