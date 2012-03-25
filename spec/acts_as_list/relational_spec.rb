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
      let(:category) { Category.create! }

      before do
        3.times do |n|
          category.items.create! position_field => n
        end
        category.should have(3).items
      end

      it_behaves_like 'a list'

      describe ".acts_as_list" do
        it "defines #scope_condition" do
          item = category.items.first
          item.scope_condition.should == {:category_id => category.id}
        end

        it "raises a NoScope error if called without a scope option" do
          lambda do
            RootItem.acts_as_list(scope: nil)
          end.should raise_exception Mongoid::ActsAsList::List::ScopeMissingError
        end
      end

      describe ".order_by_position" do
        it "works with a condition" do
          RootItem.order_by_position(:category_id => category.id).map(&position_field).should == [0,1,2]
        end
      end
    end
  end
end
