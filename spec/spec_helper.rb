$: << File.expand_path('../lib', __FILE__)
require 'rspec'
require 'rspec/autorun'
require 'database_cleaner'
require 'database_cleaner/mongoid/truncation'

require 'mongoid'
require 'acts_as_list'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db('acts_as_list_test')
end

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner['mongoid'].strategy = :truncation
  end

  config.after(:suite) do
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    # Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
  end
end
