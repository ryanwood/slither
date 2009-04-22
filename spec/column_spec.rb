require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Column do
  before(:each) do
    @name = :id
    @length = 5
    @column = Slither::Column.new(@name, @length)
  end
  
  describe "when being created" do
    it "should have a name" do
      @column.name.should == @name
    end
    
    it "should have a length" do
      @column.length.should == @length
    end
    
    it "should have a default padding" do
      @column.padding.should == :space
    end
    
    it "should have a default alignment" do
      @column.alignment.should == :right
    end
   
    it "should return a proper formatter" do
      @column.send(:formatter).should == "%5s"
    end
  end

  describe "when specifying an alignment" do
    before(:each) do
      @column = Slither::Column.new(@name, @length, :align => :left)
    end
    
    it "should only accept :right or :left for an alignment" do
      lambda{ Slither::Column.new(@name, @length, :align => :bogus) }.should raise_error(ArgumentError, "Option :align only accepts :right (default) or :left")
    end 
        
    it "should override the default alignment" do
      @column.alignment.should == :left
    end
  end
  
  describe "when specifying padding" do
    before(:each) do
      @column = Slither::Column.new(@name, @length, :padding => :zero)
    end
    
    it "should accept only :space or :zero" do
      lambda{ Slither::Column.new(@name, @length, :padding => :bogus) }.should raise_error(ArgumentError, "Option :padding only accepts :space (default) or :zero")  
    end
    
    it "should override the default padding" do
      @column.padding.should == :zero
    end
  end

  it "should return the proper unpack value for a string" do
    @column.send(:unpacker).should == 'A5'
  end
  
  describe "when typing the value" do
    it "should default to a string" do
      @column.to_type('name').should == 'name'
    end
    
    it "should support the :integer type" do
      @column = Slither::Column.new(@name, @length, :type => :integer)
      @column.to_type('234').should == 234
    end

    it "should support the :float type" do
      @column = Slither::Column.new(@name, @length, :type => :float)
      @column.to_type('234.45').should == 234.45
    end

    it "should support the :date type" do
      @column = Slither::Column.new(@name, @length, :type => :date)
      dt = @column.to_type('2009-08-22')
      dt.should be_a(Date)
      dt.to_s.should == '2009-08-22'
    end   
    
    it "should use the :date_format option with :date type if available" do
      @column = Slither::Column.new(@name, @length, :type => :date, :date_format => "%m%d%Y")
      dt = @column.to_type('08222009')
      dt.should be_a(Date)
      dt.to_s.should == '2009-08-22'
    end   
  end
  
  describe "when getting the column's the value as a string" do
    it "should default to a string" do
      @column.send(:format_as_string, 'name').should == 'name'
    end
    
    it "should raise an error if the value is longer than the length" do
      lambda { @column.send(:format_as_string, 'This string is too long') }.should raise_error(
        Slither::FormattedStringExceedsLengthError, 
        "The formatted value 'This string is too long' exceeds #{@length} chararacters, the allowable length of the '#{@name}' column."
      )
    end
    
    it "should support the :integer type" do
      @column = Slither::Column.new(@name, @length, :type => :integer)
      @column.send(:format_as_string, 234).should == '234'
    end

    it "should support the :float type" do
      @column = Slither::Column.new(:amount, 6, :type => :float)
      @column.send(:format_as_string, 234.45).should == '234.45'
    end

    it "should support the :date type" do
      dt = Date.new(2009, 8, 22)
      @column = Slither::Column.new(:date, 10, :type => :date)
      @column.send(:format_as_string, dt).should == '2009-08-22'
    end   
    
    it "should use the :date_format option with :date type if available" do
      dt = Date.new(2009, 8, 22)
      @column = Slither::Column.new(:date, 8, :type => :date, :date_format => "%m%d%Y")
      @column.send(:format_as_string, dt).should == '08222009'
    end 
  end
  
  describe "when formatting a column" do
    
    it "should return a proper formatter" do
      @column = Slither::Column.new(@name, @length, :align => :left)
      @column.send(:formatter).should == "%-5s"
    end
    
    it "should respect a right alignment" do
      @column = Slither::Column.new(@name, @length, :align => :right)
      @column.format(25).should == '   25'
    end
    
    it "should respect a left alignment" do
      @column = Slither::Column.new(@name, @length, :align => :left)
      @column.format(25).should == '25   '
    end
    
    it "should respect padding with spaces" do
      @column = Slither::Column.new(@name, @length, :padding => :space)
      @column.format(25).should == '   25'
    end
    
    it "should respect padding with zeros with integer types" do
      @column = Slither::Column.new(@name, @length, :type => :integer, :padding => :zero)
      @column.format(25).should == '00025'
    end
    
    describe "that is a float type" do
      it "should respect padding with zeros aligned right" do
        @column = Slither::Column.new(@name, @length, :type => :float, :padding => :zero, :align => :right)
        @column.format(4.45).should == '04.45'
      end
      
      it "should respect padding with zeros aligned left" do
        @column = Slither::Column.new(@name, @length, :type => :float, :padding => :zero, :align => :left)
        @column.format(4.45).should == '4.450'
      end
    end
    

  end
end