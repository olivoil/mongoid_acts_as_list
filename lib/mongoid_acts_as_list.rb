require_relative 'mongoid/acts_as_list/list'
require_relative 'mongoid/acts_as_list/configuration'

module Mongoid
  module ActsAsList
    class << self

      # Public: the configuration object used by Mongoid::ActsAsList
      #
      # Examples
      #
      #   Mongoid::ActsAsList.configuration.default_position_field
      #   #=> :position
      #
      # Returns the configuration object
      attr_accessor :configuration

      # Public: set the configuration options for Mongoid::ActsAsList
      #
      # yields the configuration object
      #
      # Examples
      #
      #    Mongoid::ActsAsList.configure do |config|
      #      # These are the default options.
      #      # Modify as you see fit:
      #      config.default_position_field = :position
      #      config.start_list_at = 0
      #    end
      #
      # Returns the configuration object
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
