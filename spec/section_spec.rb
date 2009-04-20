require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Section do
  before(:each) do
    @section = Slither::Section.new(:body)
  end
  
  it "should have no columns after creation" do
    @section.columns.should be_empty
  end
  
  it "should know it's reserved names" do
    Slither::Section::RESERVED_NAMES.should == [:spacer]
  end
  
  describe "when adding columns" do    
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
    
    it "should use a missing method to create a column" do
      @section.should have(0).columns
      @section.first_name 5
      @section.should have(1).columns
    end
    
    it "should prevent duplicate column names" do
      @section.column :id, 10
      lambda { @section.column(:id, 30) }.should raise_error(Slither::DuplicateColumnNameError, "You have already defined a column named 'id'.")
    end    
  end
  
  it "should accept and store the trap as a block" do
    @section.trap { |v| v == 4 }
    trap = @section.instance_variable_get(:@trap)
    trap.should be_a(Proc)
    trap.call(4).should == true
  end
  
  describe "when adding a template" do
    before(:each) do
      @template = mock('templated section', :columns => [1,2,3], :options => {})
      @definition = mock("definition", :templates => { :test => @template } )
      @section.definition = @definition
    end
    
    it "should ensure the template exists" do
      @definition.stub! :templates => {}
      lambda { @section.template(:none) }.should raise_error(ArgumentError)
    end
    
    it "should add the template columns to the current column list" do
      @section.template :test
      @section.should have(3).columns
    end
    
    it "should merge the template option" do
       @section = Slither::Section.new(:body, :align => :left)
       @section.definition = @definition
       @template.stub! :options => {:align => :right}
       @section.template :test
       @section.options.should == {:align => :left}
    end
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
  
  describe "when parsing a file" do
    before(:each) do
      @line = '   45      Ryan      WoodSC '
      @section = Slither::Section.new(:body)
      @column_content = { :id => 5, :first => 10, :last => 10, :state => 2 }      
    end
    
    it "should return a key for key column" do
      @column_content.each { |k,v| @section.column(k, v) }
      parsed = @section.parse(@line)
      @column_content.each_key { |name| parsed.should have_key(name) }
    end

    it "should not return a key for reserved names" do
      @column_content.each { |k,v| @section.column(k, v) }
      @section.spacer 5
      @section.should have(5).columns
      parsed = @section.parse(@line)
      parsed.should have(4).keys
    end
  end
  
  it "should try to match a line using the trap" do
    @section.trap do |line|
      line == 'hello'
    end
    @section.match('hello').should be_true
    @section.match('goodbye').should be_false
  end
end
