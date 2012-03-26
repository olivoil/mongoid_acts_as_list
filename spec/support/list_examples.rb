shared_examples_for "a list" do

  describe ".acts_as_list" do
    it "defines #position_field && .position_field" do
      item = category.items.first
      item.position_field.should == position_field
      item.class.position_field.should == position_field
    end
  end

  describe ".order_by_position" do
    it "works without conditions" do
      category.items.order_by_position.map(&position_field).should == [0,1,2]
    end

    it "sorts by created_at if positions are equal" do
      deuce = category.items.create! position_field => 1
      items = category.items.order_by_position
      items.map(&position_field).should == [0,1,1,2]
      items[2].should == deuce
    end

    it "sorts in descending order if specified" do
      deuce = category.items.create! position_field => 2, :created_at => Date.yesterday
      items = category.items.order_by_position(:desc)
      items.map(&position_field).should == [2,2,1,0]
      items[1].should == deuce
    end
  end

  describe "Insert a new item to the list" do
    it "inserts at the next available position for a given category" do
      item = category.items.create!
      item[position_field].should == 3
    end
  end

  describe "Removing items" do
    before do
      3.times do
        category.items.create!
      end
      category.reload.items.map(&position_field).should == [0,1,2,3,4,5]
    end

    describe " #destroy" do
      it "reorders the positions in the list" do
        item = category.items.where(position_field => 3).first
        item.destroy

        items = item.embedded? ? category.items : category.reload.items
        items.map(&position_field).should == [0,1,2,3,4]
      end


      it "does not shift positions if the element was already removed from the list" do
        item = category.items.where(position_field => 2).first
        item.remove_from_list
        item.destroy
        category.reload.items.map(&position_field).should == [0,1,2,3,4]
      end
    end

    describe " #remove_from_list" do
      it "sets position to nil" do
        item = category.items.where(position_field => 2).first
        item.remove_from_list
        item[position_field].should be_nil
      end

      it "is not in list anymore" do
        item = category.items.where(position_field => 3).first
        item.remove_from_list
        item.should_not be_in_list
      end

      it "reorders the positions in the list" do
        category.items.where(position_field => 0).first.remove_from_list
        category.reload.items.map(&position_field).compact.should == [0,1,2,3,4]
      end
    end
  end

  describe "#first?" do
    it "returns true if item is the first of the list" do
      category.items.order_by_position.first.should be_first
    end

    it "returns false if item is not the first of the list" do
      all_but_first = category.items.order_by_position.to_a[1..-1]
      all_but_first.map(&:first?).uniq.should == [false]
    end
  end

  describe "#last?" do
    it "returns true if item is the last of the list" do
      category.items.order_by_position.last.should be_last
    end

    it "returns false if item is not the last of the list" do
      all_but_last = category.items.order_by_position.to_a[0..-2]
      all_but_last.map(&:last?).uniq.should == [false]
    end
  end

  %w[lower_item next_item].each do |method_name|
    describe "##{method_name}" do
      it "returns the next item in the list if there is one" do
        item      = category.items.where(position_field => 1).first
        next_item = category.items.where(position_field => 2).first
        item.send(method_name).should == next_item
      end

      it "returns nil if the item is already the last" do
        item = category.items.order_by_position.last
        item.send(method_name).should be_nil
      end

      it "returns nil if the item is not in the list" do
        item = category.items.order_by_position.first
        item.remove_from_list
        item.send(method_name).should be_nil
      end
    end
  end

  %w[higher_item previous_item].each do |method_name|
    describe "##{method_name}" do
      it "returns the previous item in the list if there is one" do
        item          = category.items.where(position_field => 1).first
        previous_item = category.items.where(position_field => 0).first
        item.send(method_name).should == previous_item
      end

      it "returns nil if the item is already the first" do
        item = category.items.order_by_position.first
        item.send(method_name).should be_nil
      end

      it "returns nil if the item is not in the list" do
        item = category.items.order_by_position.last
        item.remove_from_list
        item.send(method_name).should be_nil
      end
    end
  end

  describe "#insert_at" do
    context "to a lower position" do
      let(:item) { category.items.order_by_position.last }

      it "changes the item's position" do
        item.send :insert_at, 1
        item[position_field].should == 1
      end

      it "shuffles intermediary positions" do
        positions = category.items.order_by_position.map(&position_field)
        positions.should == [0,1,2]
        item.send :insert_at, 1
        positions = category.items.order_by_position.map(&position_field)
        positions.should == [0,1,2]
      end

      it "works for items that don't have a position yet" do
        item.remove_from_list
        item.send :insert_at, 1
        item[position_field].should == 1
      end
    end

    context "to a higher position" do
      let(:item) { category.items.order_by_position.first }

      it "changes the item's position" do
        item.send :insert_at, 2
        item[position_field].should == 2
      end

      it "shuffles intermediary positions" do
        positions = category.items.order_by_position.map(&position_field)
        positions.should == [0,1,2]
        item.send :insert_at, 2
        positions = category.items.order_by_position.map(&position_field)
        positions.should == [0,1,2]
      end

      it "works for items that don't have a position yet" do
        item.remove_from_list
        item.send :insert_at, 2
        item[position_field].should == 2
      end
    end

    context "to the same position" do
      it "does nothing" do
        item = category.items.first
        lambda do
          positions = category.items.order_by_position.map(&position_field)
          positions.should == [0,1,2]
          item.send :insert_at, item[position_field]
          positions = category.items.order_by_position.map(&position_field)
          positions.should == [0,1,2]
        end.should_not change(item, position_field)
      end
    end

    context "to extreme positions" do
      it "like 0" do
        item = category.items.order_by_position.last

        item.remove_from_list
        item.send :insert_at, 0

        item[position_field].should == 0
        category.items.order_by_position.map(&position_field).should == [0,1,2]
      end
      it "like the last position" do
        item = category.items.order_by_position.first

        item.remove_from_list
        item.send :insert_at, 1

        item[position_field].should == 1
        category.items.order_by_position.map(&position_field).should == [0,1,2]
      end
      it "like the next available position" do
        item = category.items.order_by_position.first

        item.remove_from_list
        item.send :insert_at, 2

        item[position_field].should == 2
        category.items.order_by_position.map(&position_field).should == [0,1,2]
      end
    end
  end

  describe " #move" do
    context ":to =>" do
      context "an Integer" do
        it "inserts at a given position" do
          item = category.items.order_by_position.first
          item.should_receive(:insert_at).with 2
          item.move to: 2
        end
      end

      context "a Symbol" do
        [:start, :top, :end, :bottom].each do |destination|
          it "moves to #{destination}" do
            item = category.items.first
            item.should_receive("move_to_#{destination}")
            item.move to: destination
          end
        end
      end
    end

    [:before, :above, :after, :below, :forward, :backward, :lower, :higher].each do |sym|
      context "#{sym} =>" do
        it "delegates to the right method" do
          item = category.items.first
          other_item = category.items.last
          item.should_receive("move_#{sym}").with(other_item)
          item.move(sym => other_item)
        end
      end
    end

    [:backwards, :higher].each do |sym|
      context "#{sym}" do
        it "delegates to the right method" do
          item = category.items.last
          item.should_receive("move_#{sym}").with()
          item.move sym
        end
      end
    end
  end

  [:top, :start].each do |sym|
    describe "#move_to_#{sym}" do
      it "#{sym} moves an item in list to the start of list" do
        item = category.items.order_by_position.last
        item.move to: sym
        item[position_field].should == 0
        category.items.order_by_position.map(&position_field).should == [0,1,2]
      end

      it "#{sym} moves an item not in list to the start of list" do
        item = category.items.order_by_position.last
        item.remove_from_list
        item.move to: sym
        item[position_field].should == 0
        category.items.order_by_position.map(&position_field).should == [0,1,2]
      end
    end
  end

  [:end, :bottom].each do |sym|
    describe "#move_to_#{sym}" do
      it "#{sym} moves an item in list to the end of list" do
        item = category.items.order_by_position.first
        item.move to: sym
        item[position_field].should == 2
        category.reload.items.order_by_position.map(&position_field).should == [0,1,2]
      end

      it "#{sym} moves an item not in list to the end of list" do
        item = category.items.order_by_position.first
        item.remove_from_list
        item.move to: sym
        item[position_field].should == 2
        category.items.order_by_position.map(&position_field).should == [0,1,2]
      end
    end
  end

  [:forwards, :lower].each do |sym|
    describe " #move_#{sym}" do
      let(:method) { "move_#{sym}" }

      context "for the last item of the list" do
        let(:item) { category.items.order_by_position.last }

        it "does not change the item's position" do
          lambda do
            item.send method
          end.should_not change(item, position_field)
        end

        it "keeps items ordered" do
          item.send method
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end

        it "returns false" do
          item.send(method).should be_false
        end
      end

      context "for any other item" do
        let(:item) { category.items.order_by_position.first }

        it "moves to the next position" do
          lambda do
            item.send method
          end.should change(item, position_field).by(1)
        end

        it "moves to the nth next position" do
          lambda do
            item.send method, 2
          end.should change(item, position_field).by(2)
        end

        it "moves to the end of the list if n is too high" do
          lambda do
            item.send method, 9
          end.should change(item, position_field).by(2)
        end

        it "keeps items ordered" do
          item.send method, 2
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end

        it "returns true" do
          item.send(method).should be_true
        end
      end
    end
  end

  [:backwards, :higher].each do |sym|
    describe " #move_#{sym}" do
      let(:method) { "move_#{sym}" }

      context "for the first item of the list" do
        let(:item) { category.items.order_by_position.first }

        it "does not change the item's position" do
          lambda do
            item.send method
          end.should_not change(item, position_field)
        end

        it "keeps items ordered" do
          item.send method
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end

        it "returns false" do
          item.send(method).should be_false
        end
      end

      context "for any other item" do
        let(:item) { category.items.order_by_position.last }

        it "moves to the previous position" do
          lambda do
            item.send method
          end.should change(item, position_field).by(-1)
        end

        it "moves to the nth previous position" do
          lambda do
            item.send method, 2
          end.should change(item, position_field).by(-2)
        end

        it "moves to the end of the list if n is too high" do
          lambda do
            item.send method, 9
          end.should change(item, position_field).by(-2)
        end

        it "keeps items ordered" do
          item.send method
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end

        it "returns true" do
          item.send(method).should be_true
        end
      end
    end
  end

  [:before, :above].each do |sym|
    describe " #move_#{sym}" do
      before do
        item.send("move_#{sym}", other_item)
      end

      context "towards the start" do
        let(:other_item) { category.items.order_by_position.first }
        let(:item)       { category.items.order_by_position.last  }

        it "moves to the same position as other_item" do
          item[position_field].should == 0
        end

        it "shifts other_item " do
          other_item.reload[position_field].should == 1
        end

        it "shifts any item after that by 1" do
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end
      end
      context "towards the end" do
        let(:item)       { category.items.order_by_position.first }
        let(:other_item) { category.items.order_by_position.last  }

        it "moves to the same position as other_item" do
          item[position_field].should == 1
        end

        it "shifts other_item " do
          other_item[position_field].should == 2
        end

        it "shifts any item after that by 1" do
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end
      end
    end
  end

  [:after, :below].each do |sym|
    describe " #move_#{sym}" do
      before do
        item.send("move_#{sym}", other_item)
      end

      context "towards the start" do
        let(:other_item) { category.items.order_by_position.first }
        let(:item)       { category.items.order_by_position.last  }

        it "moves to other_item's next position" do
          item[position_field].should == 1
        end

        it "shifts any item before that by -1" do
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end
      end
      context "towards the end" do
        let(:item)       { category.items.order_by_position.first }
        let(:other_item) { category.items.order_by_position.last  }

        it "moves to the same position as other_item" do
          item[position_field].should == 2
        end

        it "shifts any item before that by -1" do
          category.items.order_by_position.map(&position_field).should == [0,1,2]
        end
      end
    end
  end

  describe "#start_position_in_list" do
    before do
      @original_start = Mongoid::ActsAsList.configuration.start_list_at
    end
    after do
      Mongoid::ActsAsList.configure {|c| c.start_list_at = @original_start}
    end

    it "is configurable" do
      category.items.destroy_all
      start = 1
      Mongoid::ActsAsList.configure {|c| c.start_list_at = start}
      item = category.items.create!
      item[position_field].should == start
      item = category.items.create!
      item[position_field].should == start+1
    end
  end
end
