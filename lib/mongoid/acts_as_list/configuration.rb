module Mongoid
  module ActsAsList
    class Configuration
      attr_accessor :default_position_field

      def initialize
        @default_position_field = :position
      end
    end
  end
end
