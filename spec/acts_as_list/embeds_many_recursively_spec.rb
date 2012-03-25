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
      it_behaves_like 'a list' do
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
      end

      require 'delegate'

      it_behaves_like 'a list' do
        let(:category) do
          cat  = Category.create!

          item = cat.items.create!

          3.times do |n|
            item.child_items.create! position_field => n
          end

          class SubItemAsCategory < SimpleDelegator
            def items
              __getobj__.child_items
            end
            def reload
              __getobj__.reload
              self
            end
          end

          SubItemAsCategory.new(item)
        end
      end
    end
  end
end
