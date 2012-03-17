module ActsAsList
  module Relational
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_list options = {}
        options.reverse_merge! :field => 'position'

        define_field options.fetch(:field).to_sym
        define_scope options.fetch(:scope).to_sym
      end

      def order_by_position(conditions = {}, order = :asc)
        where( conditions ).order_by( [position_column, order] )
      end

    private

      def define_field(field_name)
        field field_name, type: Integer #, default: -> { next_available_position }

        set_callback :save, :before do |doc|
          doc[field_name] = doc.next_available_position unless doc[field_name]
        end

        [:define_method, :define_singleton_method].each do |define_method|
          send(define_method, :position_column) { field_name }
        end
      end

      def define_scope(scope_name)
        scope_name = "#{scope_name}_id".intern if scope_name.to_s !~ /_id$/
        define_method(:scope_condition) { {scope_name => self[scope_name]} }
      end
    end

    def next_available_position
      if item = last_item_in_list
        item[position_column] + 1
      else
        0
      end
    end

  private

    def last_item_in_list
      self.class.order_by_position( scope_condition ).last
    end
  end
end
