class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :items
end

class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::ActsAsList
  belongs_to :category
  acts_as_list :scope => :category
end
