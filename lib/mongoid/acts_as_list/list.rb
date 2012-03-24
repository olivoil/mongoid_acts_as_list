module Mongoid::ActsAsList
  module List
    extend ActiveSupport::Concern

    autoload :Root     , 'mongoid/acts_as_list/list/root.rb'
    autoload :Embedded , 'mongoid/acts_as_list/list/embedded.rb'

    class ScopeMissingError < RuntimeError; end

    module ClassMethods
      def acts_as_list options = {}
        field = options.fetch(:field, Mongoid::ActsAsList.configuration.default_position_field).try(:to_sym)
        scope = options.fetch(:scope, nil).try(:to_sym)

        include list_submodule
        define_position_field field
        define_position_scope scope
      end

      def order_by_position(conditions = {}, order = :asc)
        order, conditions = [conditions || :asc, {}] unless conditions.is_a? Hash
        where( conditions ).order_by [[position_field, order], [:created_at, order]]
      end

    private

      def list_submodule
        embedded? ? Embedded : Root
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

    # Public: Indicates if an item is in the list
    #
    # Returns true if the item is in the list or false if not
    def in_list?
      self[position_field].present?
    end

    # Public: Indicates if an item is not in the list
    #
    # Returns true if the item is not in the list or false if it is
    def not_in_list?
      !in_list?
    end

    # Public: Indicates if an item is the first of the list
    #
    # Returns true if the item is the first in the list or false if not
    def first?
      self[position_field] == start_position_in_list
    end

    # Public: Indicates if an item is the last of the list
    #
    # Returns true if the item is the last in the list or false if not
    def last?
      self[position_field] == last_item_in_list[position_field]
    end

    # Public: Gets the following item in the list
    #
    # Returns the next item in the list
    #   or nil if there isn't a next item
    def next_item
      return unless in_list?
      items_in_list.where(position_field => self[position_field]+1).first
    end
    alias_method :higher_item, :next_item

    # Public: Gets the preceding item in the list
    #
    # Returns the previous item in the list
    #   or nil if there isn't a previous item
    def previous_item
      return unless in_list?
      items_in_list.where(position_field => self[position_field]-1).first
    end
    alias_method :lower_item, :previous_item

    # Public: Insert at a given position in the list
    #
    # new_position - an Integer indicating the position to insert the item at
    #
    # Returns nothing
    def insert_at(new_position)
      insert_space_at(new_position)
      update_attribute(position_field, new_position)
    end

  private

    # Internal: Make space in the list at a given position number
    #   used when moving a item to a new position in the list.
    #
    # position - an Integer representing the position number
    #
    # Returns nothing
    def insert_space_at(position)
      from = self[position_field] || next_available_position_in_list
      to   = position

      if from < to
        shift_position for: items_between(from, to + 1), by: -1
      else
        shift_position for: items_between(to - 1, from), by: 1
      end
    end

    def items_between(from, to, options = {})
      strict = options.fetch(:strict, true)
      if strict
        items_in_list.where(position_field.gt => from, position_field.lt => to)
      else
        items_in_list.where(position_field.gte => from, position_field.lte => to)
      end
    end

    def last_item_in_list
      items_in_list.order_by_position.last
    end

    def previous_items_in_list
      items_in_list.where(position_field.lt => self[position_field])
    end

    def next_items_in_list
      items_in_list.where(position_field.gt => self[position_field])
    end

    def shift_later_items_towards_start_of_list
      return unless in_list?
      shift_position for: next_items_in_list, by: -1
    end

    def next_available_position_in_list
      if item = last_item_in_list
        item[position_field] + 1
      else
        start_position_in_list
      end
    end

    def start_position_in_list
      Mongoid::ActsAsList.configuration.start_list_at
    end
  end
end
