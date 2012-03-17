module ActsAsList
  module Relational
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_list options = {}
        options.reverse_merge! :column => 'position'

        field_name = options.fetch(:column).to_sym
        field field_name, type: Integer, default: -> { next_available_position }
        define_method :position_column do
          field_name
        end
        define_singleton_method :position_column do
          field_name
        end

        scope = options.fetch(:scope).to_sym
        scope = "#{scope}_id".intern if scope.to_s !~ /_id$/

        define_method :scope_condition do
          {scope => self[scope.to_s]}
        end
      end

      def order_by_position(conditions = {}, order = :asc)
        where( conditions ).order_by( [position_column, order] )
      end
    end

  private

    def next_available_position
      if item = last_item
        item[position_column] + 1
      else
        0
      end
    end

    def last_item
      self.class.order_by_position( scope_condition ).last
    end
  end
end
