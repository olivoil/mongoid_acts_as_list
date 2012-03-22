shared_examples_for "a list" do
  describe ".acts_as_list" do
    it "defines #position_field && .position_field" do
      item = category_1.items.first
      item.position_field.should == position_field
      item.class.position_field.should == position_field
    end
  end

  describe ".order_by_position" do
    it "works without conditions" do
      category_1.items.order_by_position.map(&position_field).should == [0,1,2]
    end

    it "sorts by created_at if positions are equal" do
      deuce = category_1.items.create! position_field => 1
      items = category_1.items.order_by_position
      items.map(&position_field).should == [0,1,1,2]
      items[2].should == deuce
    end

    it "sorts in descending order if specified" do
      deuce = category_1.items.create! position_field => 2, :created_at => Date.yesterday
      items = category_1.items.order_by_position(:desc)
      items.map(&position_field).should == [2,2,1,0]
      items[1].should == deuce
    end
  end

  describe "#start_position_in_list", :focus do
    it "is configurable" do
      category_3.items.should be_empty
      start = 1
      Mongoid::ActsAsList.configure {|c| c.start_list_at = start}
      item = category_3.items.create!
      item[position_field].should == start
      item = category_3.items.create!
      item[position_field].should == start+1
    end
  end

  describe "Insert a new item to the list" do
    it "inserts at the next available position for a given category" do
      item = category_1.items.create!
      item[position_field].should == 3
    end
  end

  describe "Removing items" do
    before do
      3.times do
        category_1.items.create!
      end
      category_1.reload.items.map(&position_field).should == [0,1,2,3,4,5]
    end

    describe " #destroy" do
      it "reorders the positions in the list" do
        item = category_1.items.where(position_field => 3).first
        item.destroy

        items = item.embedded? ? category_1.items : category_1.reload.items
        items.map(&position_field).should == [0,1,2,3,4]
      end


      it "does not shift positions if the element was already removed from the list" do
        item = category_1.items.where(position_field => 2).first
        item.remove_from_list
        item.destroy
        category_1.reload.items.map(&position_field).should == [0,1,2,3,4]
      end
    end

    describe " #remove_from_list" do
      it "sets position to nil" do
        item = category_1.items.where(position_field => 2).first
        item.remove_from_list
        item[position_field].should be_nil
      end

      it "is not in list anymore" do
        item = category_1.items.where(position_field => 3).first
        item.remove_from_list
        item.should_not be_in_list
      end

      it "reorders the positions in the list" do
        category_1.items.where(position_field => 0).first.remove_from_list
        category_1.reload.items.map(&position_field).compact.should == [0,1,2,3,4]
      end
    end
  end
end
