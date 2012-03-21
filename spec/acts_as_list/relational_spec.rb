require 'spec_helper'

describe Mongoid::ActsAsList::List do
  [:position, :number].each do |default_field_name|
    let(:position_field) { default_field_name }

    before do
      Mongoid::ActsAsList.configure do |config|
        config.default_position_field = position_field
      end

      require 'fixtures/relational_models'
    end


    describe Mongoid::ActsAsList::List::Root do
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

      it_behaves_like 'a list'

      describe ".acts_as_list" do
        it "defines #scope_condition" do
          item = category_1.items.first
          item.scope_condition.should == {:category_id => category_1.id}
        end
      end

      describe ".order_by_position" do
        it "works with a condition" do
          RootItem.order_by_position(:category_id => category_2.id).map(&position_field).should == [0,1,2]
        end
      end

      describe "Insert a new item to the list" do
        it "scopes list to the relation" do
          item_1 = category_1.items.create!
          item_2 = category_2.items.create!

          item_1[position_field].should == item_2[position_field]
          item_2[position_field].should == 3
        end
      end
    end
  end
end
