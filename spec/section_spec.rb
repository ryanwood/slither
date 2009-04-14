require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Section do
  before(:each) do
    @section = Slither::Section.new(:body)
  end
  
  it "should have no columns after creation" do
    @section.columns.should be_empty
  end
  
  it "should build an ordered column list" do
    @section.should have(0).columns
    
    col1 = @section.column :id, 10
    col2 = @section.column :name, 30
    col3 = @section.column :state, 2
    
    @section.should have(3).columns
    @section.columns[0].should be(col1)
    @section.columns[1].should be(col2)
    @section.columns[2].should be(col3)
  end
  
  it "should create spacer columns" do
    @section.should have(0).columns
    @section.spacer(5)
    @section.should have(1).columns
  end
  
  it "can should override the alignment of the definition" do
    section = Slither::Section.new('name', :align => :left)
    section.options[:align].should == :left
  end
  
  describe "when formatting a row" do    
    before(:each) do
      @data = { :id => 3, :name => "Ryan" }
    end
    
    it "should default to string data aligned right" do
      @section.column(:id, 5)
      @section.column(:name, 10)      
      @section.format( @data ).should == "    3      Ryan"      
    end
    
    it "should left align if asked" do
      @section.column(:id, 5)
      @section.column(:name, 10, :align => :left)  
      @section.format(@data).should == "    3Ryan      "      
    end
  end
  

  
  # it "should pass the definition to the block" do
  #   yielded = nil
  #   Slither.define(@name) do |y|
  #     yielded = y
  #   end
  #   yielded.should be_a( Slither::Definition )
  # end
  
end