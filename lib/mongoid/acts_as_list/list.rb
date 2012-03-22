module Mongoid::ActsAsList
  module List
    extend ActiveSupport::Concern

    autoload :Root     , 'mongoid/acts_as_list/list/root.rb'
    autoload :Embedded , 'mongoid/acts_as_list/list/embedded.rb'

    class NoScopeError < RuntimeError; end

    module ClassMethods
      def acts_as_list options = {}
        field = options.fetch(:field, Mongoid::ActsAsList.configuration.default_position_field).try(:to_sym)
        scope = options.fetch(:scope, nil).try(:to_sym)

        include_list_submodule
        define_position_field field
        define_position_scope scope
      end

      def order_by_position(conditions = {}, order = :asc)
        order, conditions = [conditions || :asc, {}] unless conditions.is_a? Hash
        where( conditions ).order_by [[position_field, order], [:created_at, order]]
      end

      def shift_positions
        raise NotImplementedError
      end

    private

      def include_list_submodule
        if embedded?
          include Embedded
        else
          include Root
        end
      end

      def define_position_field(field_name)
        field field_name, type: Integer

        set_callback :validation, :before, if: -> { new? && not_in_list? } do |doc|
          doc[field_name] = doc.send(:next_available_position_in_list)
        end

        set_callback :destroy, :after, :shift_later_items_towards_start_of_list, if: -> { in_list? }

        [:define_method, :define_singleton_method].each do |define_method|
          send(define_method, :position_field) { field_name }
        end
      end
    end

    ## InstanceMethods

    def remove_from_list
      return unless in_list?
      shift_later_items_towards_start_of_list
      update_attributes(position_field => nil)
    end

    def in_list?
      self[position_field].present?
    end

    def not_in_list?
      !in_list?
    end

  private

    def last_item_in_list
      items_in_list.order_by_position.last
    end

    def later_items
      items_in_list.where(position_field.gt => self[position_field])
    end

    def shift_later_items_towards_start_of_list
      return unless in_list?
      shift_position for: later_items, by: -1
    end

    def next_available_position_in_list
      if item = last_item_in_list
        item[position_field] + 1
      else
        start_position_in_list
      end
    end

    def items_in_list
      raise NotImplementedError
    end

    def start_position_in_list
      0
    end
  end
end
