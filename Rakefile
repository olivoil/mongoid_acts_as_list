require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rdoc/task'

desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb"
end

desc "Open an irb session preloaded with this library"
task :irb do
  sh "irb -rubygems -r ./lib/#{name}.rb"
end

desc "Open an pry session preloaded with this library"
task :pry do
  sh "pry -r ./lib/#{name}.rb"
end
