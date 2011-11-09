require 'spec_helper'

describe List do

  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:list) {FactoryGirl.create(:list, :user => user)}
  
  describe "#sharees" do
    it "should find all users which have received a list" do
      user2.receive_list(list, User::LIST_PERMISSIONS[0])
      list.sharees.should include(user2)
    end 
    
    it "should not include the owner of the list" do
      user2.receive_list(list, User::LIST_PERMISSIONS[0])
      list.sharees.should_not include(user)
    end
  end
  
  describe "after_create" do
    it "should add the list to the owner's lists_organized" do
      list.user.lists_organized.should == [{
        "list_id"    => list.id.to_s,
        "permission" => User::LIST_PERMISSIONS[2]
      }]
    end
  end
end
