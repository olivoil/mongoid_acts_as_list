require 'spec_helper'

describe Mongoid::ActsAsList do
  [:position, :number].each do |default_field_name|
    let(:position_field) { default_field_name }

    before do
      Mongoid::ActsAsList.configure do |config|
        config.default_position_field = position_field
      end

      require 'fixtures/relational_models'
    end

    describe Mongoid::ActsAsList::Relational do
      let(:category_1) { Category.create! }
      let(:category_2) { Category.create! }
      let(:category_3) { Category.create! }

      before do
        [category_1, category_2].each do |cat|
          3.times do |n|
            cat.items.create! position_field => n
          end
          cat.should have(3).items
        end
      end

      describe ".acts_as_list" do
        it "defines #position_field && .position_field" do
          item = category_1.items.first
          item.position_field.should == position_field
          Item.position_field.should == position_field
        end

        it "defines #scope_condition" do
          item = category_1.items.first
          item.scope_condition.should == {:category_id => category_1.id}
        end
      end

      describe ".order_by_position" do
        it "works without conditions" do
          category_1.items.order_by_position.map(&position_field).should == [0,1,2]
        end

        it "words with a condition" do
          Item.order_by_position(:category_id => category_2.id).map(&position_field).should == [0,1,2]
        end

        it "sorts by created_at if positions are equal" do
          deuce = category_1.items.create! position_field => 1
          items = category_1.items.order_by_position
          items.map(&position_field).should == [0,1,1,2]
          items[2].should == deuce
        end

        it "sorts descendenly if specified" do
          deuce = category_1.items.create! position_field => 2, :created_at => Date.yesterday
          items = category_1.items.order_by_position(:desc)
          items.map(&position_field).should == [2,2,1,0]
          items[1].should == deuce
        end
      end

      describe "Insert a new item to the list" do
        it "inserts at the next available position for a given category" do
          item = category_1.items.create!
          item[position_field].should == 3
        end

        it "scopes list to the relation" do
          item_1 = category_1.items.create!
          item_2 = category_2.items.create!

          item_1[position_field].should == item_2[position_field]
          item_2[position_field].should == 3
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
            item[position_field].should == n
            item.next_available_position.should == n+1
          end
        end
      end
    end
  end
end
