require_relative 'mongoid/acts_as_list/list'
require_relative 'mongoid/acts_as_list/configuration'
require_relative 'mongoid/acts_as_list/version'

module Mongoid
  module ActsAsList
    class << self
      attr_accessor :configuration

      def configure
        self.configuration ||= Configuration.new
        yield(configuration) if block_given?
      end

      def included base
        self.configure
        base.send :include, List
      end
    end
  end
end
