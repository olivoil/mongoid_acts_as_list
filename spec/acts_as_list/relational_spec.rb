require 'spec_helper'
require 'fixtures/relational_models'

describe ActsAsList::Relational do
  let(:category_1) { Category.create! }
  let(:category_2) { Category.create! }
  let(:category_3) { Category.create! }

  before do
    [category_1, category_2].each do |cat|
      3.times do |n|
        cat.items.create! position: n
      end
      cat.should have(3).items
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

  describe ".acts_as_list" do
    it "defines #position_column && .position_column" do
      item = category_1.items.first
      item.position_column.should == :position
      Item.position_column.should == :position
    end

    it "defines #scope_condition" do
      item = category_1.items.first
      item.scope_condition.should == {:category_id => category_1.id}
    end
  end

  describe ".order_by_position" do
    it "works without conditions" do
      category_1.items.order_by_position.map(&:position).should == [0,1,2]
    end

    it "words with a condition" do
      Item.order_by_position(:category_id => category_2.id).map(&:position).should == [0,1,2]
    end

    it "sorts by created_at if positions are equal" do
      deuce = category_1.items.create! position: 1
      items = category_1.items.order_by_position
      items.map(&:position).should == [0,1,1,2]
      items[2].should == deuce
    end

    it "sorts descendenly if specified" do
      deuce = category_1.items.create! position: 2, created_at: Date.yesterday
      items = category_1.items.order_by_position(:desc)
      items.map(&:position).should == [2,2,1,0]
      items[1].should == deuce
    end
  end

  describe "#next_available_position" do
    it "starts at 0 when there are no items in the list" do
      item = category_3.items.build
      item.next_available_position.should == 0
    end

    it "increments each time an item is added to the list" do
      5.times do |n|
        item = category_3.items.create!
        item.position.should == n
        item.next_available_position.should == n+1
      end
    end
  end
end
