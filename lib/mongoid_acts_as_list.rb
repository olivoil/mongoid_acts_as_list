module Mongoid
  module ActsAsList
    class << self
      attr_accessor :configuration
    end

    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
    end

    def self.included base
      self.configure

      if base.embedded?
        base.send :include, Embedded
      else
        base.send :include, Relational
      end
    end

    autoload :Relational    , 'mongoid/acts_as_list/relational.rb'
    autoload :Embedded      , 'mongoid/acts_as_list/embedded.rb'
    autoload :Configuration , 'mongoid/acts_as_list/configuration.rb'
    autoload :VERSION       , 'mongoid/acts_as_list/version.rb'
  end
end
