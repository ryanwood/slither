require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Column do
  before(:each) do
    @name = :id
    @length = 5    
  end
  
  it "should have a name" do
    column = Slither::Column.new(@name, @length)
    column.name.should == @name
  end
  
  it "should have a length" do
    column = Slither::Column.new(@name, @length)
    column.length.should == @length
  end
  
  it "should return the proper unpack value for a string" do
  	c = Slither::Column.new(:name, 10)
  	c.unpacker.should == 'A10'
  end

end