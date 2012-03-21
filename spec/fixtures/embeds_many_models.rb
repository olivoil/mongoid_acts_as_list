class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :items, class_name: 'EmbeddedItem'
end

class EmbeddedItem
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ActsAsList

  embedded_in :category
  acts_as_list
end
