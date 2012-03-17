require 'spec_helper'

describe Mongoid::ActsAsList do
  it "has a version" do
    Mongoid::ActsAsList::VERSION.should match(/^\d+\.\d+\.\d+$/)
  end
end
