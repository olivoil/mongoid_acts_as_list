module Mongoid
  module ActsAsList
    class Configuration
      attr_accessor :default_position_field, :start_list_at

      def initialize
        @default_position_field = :position
        @start_list_at = 0
      end
    end
  end
end
