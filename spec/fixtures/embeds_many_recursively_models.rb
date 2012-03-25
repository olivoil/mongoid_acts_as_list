class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :items
end

class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ActsAsList

  embedded_in :category
  recursively_embeds_many
  acts_as_list
end
