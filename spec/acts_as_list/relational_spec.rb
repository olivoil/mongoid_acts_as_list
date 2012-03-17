require 'spec_helper'

class Category
  include Mongoid::Document
  has_many :items
end

class Item
  include Mongoid::Document
  include Mongoid::ActsAsList
  belongs_to :category
  acts_as_list :scope => :category
end

describe ActsAsList::Relational do
  let(:category_1) { Category.create! }
  let(:category_2) { Category.create! }
  let(:category_3) { Category.create! }

  before do
    3.times do |n|
      category_1.items.create!
      category_2.items.create!
    end
  end

  describe "Insert a new item to the list" do
    it "inserts at the next available position for a given category" do
      item = category_1.items.create!
      item.position.should == 3
    end

    it "scopes list to the relation" do
      item_1 = category_1.items.create!
      item_2 = category_2.items.create!

      item_1.position.should == item_2.position
      item_2.position.should == 3
    end
  end

  describe ".acts_as_list", focus: true do
    it "defines #scope_condition" do
      item = category_1.items.first
      item.scope_condition.should == {:category_id => item.category_id}
    end
  end

  describe ".order_by_position" do
    it "works without conditions" do
      category_1.items.order_by_position.map(&:position).should == [0,1,2]
    end

    it "retrieves last item when needed" do
      last_item = category_1.items.order_by_position.last
      (last_item[last_item.position_column] + 1).should == last_item.send(:next_available_position)
    end
  end
end
