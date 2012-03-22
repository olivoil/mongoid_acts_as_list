module Mongoid::ActsAsList
  module List::Embedded
    extend ActiveSupport::Concern

    included do
      raise List::NoScopeError, "Mongoid::ActsAsList::Embedded can only be included in embedded documents" unless embedded?
    end

    module ClassMethods
      private

      def define_position_scope(scope_name)
        define_method(:scope_condition) { {position_field.ne => nil} }
      end
    end

    ## InstanceMethods
    private

    def shift_position options = {}
      criteria    = options.fetch(:for, to_criteria)
      by_how_much = options.fetch(:by, 1)

      criteria.each do |doc|
        doc.inc(position_field, by_how_much)
      end
    end

    def to_criteria
      embedded_collection.where(_id: _id)
    end

    def items_in_list
      embedded_collection.where(scope_condition)
    end

    def root_collection
      _parent.db.collection(_parent.collection.name)
    end

    def embedded_collection
      _parent.send(metadata.name)
    end
  end
end
