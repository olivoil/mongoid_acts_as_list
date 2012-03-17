require 'rspec'
require 'rspec/autorun'
require 'database_cleaner'
require 'database_cleaner/mongoid/truncation'

require 'mongoid'
require_relative '../lib/mongoid_acts_as_list'

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db('acts_as_list_test')
end

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:suite) do
    DatabaseCleaner['mongoid'].strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
