module Mongoid::ActsAsList
  module List
    extend ActiveSupport::Concern

    autoload :Root     , 'mongoid/acts_as_list/list/root.rb'
    autoload :Embedded , 'mongoid/acts_as_list/list/embedded.rb'

    class ScopeMissingError < RuntimeError; end

    module ClassMethods

      # Public: class macro to enable the ActsAsList module
      #
      # options - a Hash of options
      #             :field - the name of the field to hold the position number as a Symbol or a String (optional)
      #             :scope - the name of the association to scope the list for (required for non-embedded models)
      #
      # Examples
      #
      #   ## on a belong_to relation
      #
      #   class List
      #     include Mongoid::Document
      #
      #     has_many :items
      #   end
      #
      #   class Item
      #     include Mongoid::Document
      #     include Mongoid::ActsAsList
      #
      #     belongs_to :list
      #     acts_as_list scope: :list, field: :position
      #   end
      #
      #
      #   ## on a embedded_in relation
      #
      #   class List
      #     include Mongoid::Document
      #
      #     embeds_many :items
      #   end
      #
      #   class Item
      #     include Mongoid::Document
      #     include Mongoid::ActsAsList
      #
      #     embedded_in :list
      #     acts_as_list field: :num
      #   end
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

    # Public: Moves the item to new position in the list
    #
    # where - a Symbol in [:forward, :lower, :backward, :higher]
    #         or Hash specifying where to move the item:
    #           :to                - an Integer representing a position number
    #                                or a Symbol from the list :start, :top, :end, :bottom
    #           :before, :above    - another object in the list
    #           :after: , :below   - another object in the list
    #           :forward, :lower   - an Integer specify by how much to move the item forward.
    #                                will stop moving the item when it reaches the end of the list
    #           :backward, :higher - an Integer specify by how much to move the item forward.
    #                                will stop moving the item when it reaches the end of the list
    #
    #
    # Examples
    #
    #   item.move to: 3
    #   #=> moves item to the 3rd position
    #
    #   item.move to: :start
    #   #=> moves item to the first position in the list
    #
    #   other_item.position #=> 3
    #
    #   item.move before: other_item
    #   #=> moves item to position 3 and other_item to position 4
    #
    #   item.move after: other_item
    #   #=> moves item to position 4
    #
    #   item.move backward: 3
    #   #=> move item 3 positions closer to the start of the list
    #
    #   item.move :forward
    #   #=> same as item.move(forward: 1)
    #
    # Returns nothing
    def move(where = {})
      if where.is_a? Hash
        options = [:to, :before, :above, :after, :below, :forward, :forwards, :lower, :backward, :backwards, :higher]

        prefix, destination = where.each.select { |k, _| options.include? k }.first
        raise ArgumentError, "#move requires one of the following options: #{options.join(', ')}" unless prefix

        send("move_#{prefix}", destination)
      else
        destination = where

        send("move_#{destination}")
      end
    end

    # Public: Moves the item to another position
    #
    # destination - a Symbol among :start, :end, :top, :bottom
    #               or an Integer indicating the new position number to move the item to
    def move_to(destination)
      if destination.is_a? Symbol
        send("move_to_#{destination}")
      else
        destination = position_within_list_boundaries(destination)
        insert_at destination
      end
    end

    # Public: Moves the item to the end of the list
    def move_to_end
      new_position = in_list? ? last_position_in_list : next_available_position_in_list
      insert_at new_position
    end
    alias_method :move_to_bottom, :move_to_end

    # Public: Moves the item to the start of the list
    def move_to_start
      insert_at start_position_in_list
    end
    alias_method :move_to_top, :move_to_start

    # Public: Moves the item closer to the end of the list
    #
    # by_how_much - The number of position to move the item by (default: 1)
    def move_forwards by_how_much = 1
      move_to(self[position_field] + by_how_much) unless last?
    end
    alias_method :move_lower  , :move_forwards
    alias_method :move_forward, :move_forwards

    # Public: Moves the item closer to the start of the list
    #
    # by_how_much - The number of position to move the item by (default: 1)
    def move_backwards by_how_much = 1
      move_to(self[position_field] - by_how_much) unless first?
    end
    alias_method :move_higher  , :move_backwards
    alias_method :move_backward, :move_backwards

    # Public: Moves the item before another one in the list
    #
    # other_item - another item of the list
    def move_before(other_item)
      destination = other_item[position_field]
      origin = self[position_field]

      if origin > destination
        insert_at destination
      else
        insert_at destination - 1
      end
    end
    alias_method :move_above, :move_before

    # Public: Moves the item after another one in the list
    #
    # other_item - another item of the list
    def move_after(other_item)
      destination = other_item[position_field]
      origin = self[position_field]

      if origin > destination
        insert_at destination + 1
      else
        insert_at destination
      end
    end
    alias_method :move_below, :move_after

    # Public: Removes the item from the list
    #
    # Returns true if the item was removed, false if not
    def remove_from_list
      return true unless in_list?
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
    alias_method :lower_item, :next_item

    # Public: Gets the preceding item in the list
    #
    # Returns the previous item in the list
    #   or nil if there isn't a previous item
    def previous_item
      return unless in_list?
      items_in_list.where(position_field => self[position_field]-1).first
    end
    alias_method :higher_item, :previous_item

    # Public: Insert at a given position in the list
    #         for API compatibility with AR acts_as_list
    #
    # new_position - an Integer indicating the position to insert the item at
    #
    # Returns true if the element's position was updated, false if not
    def insert_at(new_position)
      insert_space_at(new_position)
      update_attribute(position_field, new_position)
    end

    # Public: increments the position number without affecting other items
    #         for API compatibility with AR acts_as_list
    def increment_position
      inc(position_field, 1)
    end

    # Public: decrements the position number without affecting other items
    #         for API compatibility with AR acts_as_list
    def decrement_position
      inc(position_field, -1)
    end

    # Public: returns the default position symbol as defined in the configuration
    #         for API compatibility with AR acts_as_list
    def default_position
      Mongoid::ActsAsList.configuration.default_position_field
    end

    # Public: returns true if the model uses the default position field name as defined in the configuration
    #         for API compatibility with AR acts_as_list
    def default_position?
      position_field == default_position
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

    # Internal: get items of the list between two positions
    #
    # from    - an Integer representing the first position number in the range
    # to      - an Integer representing the last position number in the range
    # options - an Hash of options
    #           :strict - a Boolean indicating if the range is inclusing (false) or exclusive (true) (default: true)
    #
    # Returns a Mongoid::Criteria containing the items between the range
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

    def last_position_in_list
      last_item_in_list.try(position_field)
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

    def first_position_in_list
      Mongoid::ActsAsList.configuration.start_list_at
    end
    alias_method :start_position_in_list, :first_position_in_list

    def position_within_list_boundaries(position)
      if position < start_position_in_list
        position = start_position_in_list
      elsif position > last_position_in_list
        position = last_position_in_list
      end

      position
    end
  end
end
