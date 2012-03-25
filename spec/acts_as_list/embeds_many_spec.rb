require 'spec_helper'

describe Mongoid::ActsAsList::List do
  [:position, :number].each do |default_field_name|
    let(:position_field) { default_field_name }

    before do
      Mongoid::ActsAsList.configure do |config|
        config.default_position_field = position_field
      end

      require 'fixtures/embeds_many_models'
    end

    describe Mongoid::ActsAsList::List::Embedded do
      let(:category) { Category.create! }

      before do
        3.times do |n|
          category.items.create! position_field => n
        end
        category.should have(3).items
      end

      it "should be embedded" do
        EmbeddedItem.should be_embedded
      end

      it "should not include ActsAsList::Relational" do
        EmbeddedItem.included_modules.should_not include Mongoid::ActsAsList::List::Root
      end

      it_behaves_like 'a list'

      describe ".acts_as_list" do
        it "defines #scope_condition" do
          item = category.items.first
          item.scope_condition.should == {position_field.ne => nil}
        end
      end
    end
  end
end
