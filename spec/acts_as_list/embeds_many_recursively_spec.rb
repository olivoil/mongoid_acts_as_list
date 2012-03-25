require 'spec_helper'

describe Mongoid::ActsAsList::List do
  [:position, :number].each do |default_field_name|
    let(:position_field) { default_field_name }

    before do
      Mongoid::ActsAsList.configure do |config|
        config.default_position_field = position_field
      end

      require 'fixtures/embeds_many_recursively_models'
    end

    describe Mongoid::ActsAsList::List::Embedded do
      let(:category) { Category.create! }

      before do
        3.times do |n|
          item = category.items.create! position_field => n

          3.times do |x|
            item.child_items.create! position_field => x
          end

          item.should have(3).child_items
        end

        category.should have(3).items
      end

      it_behaves_like 'a list'

    end
  end
end
