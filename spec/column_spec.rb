require 'slither'

describe Slither::Column do
  let(:name) { :id }
  let(:length) { 5 }
  let(:column) { Slither::Column.new(name, length) }

  describe "when being created" do
    it "should have a name" do
      column.name.should == name
    end

    it "should have a length" do
      column.length.should == length
    end

    it "should have a default padding" do
      column.padding.should == :space
    end

    it "should have a default alignment" do
      column.alignment.should == :right
    end

    it "should return a proper formatter" do
      column.send(:formatter).should == "%5s"
    end
  end

  describe "when specifying an alignment" do
    let(:column) { Slither::Column.new(name, length, :align => :left) }

    it "should only accept :right or :left for an alignment" do
      lambda{ Slither::Column.new(name, length, :align => :bogus) }.should raise_error(ArgumentError, "Option :align only accepts :right (default) or :left")
    end

    it "should override the default alignment" do
      column.alignment.should == :left
    end
  end

  describe "when specifying padding" do
    let(:column) { Slither::Column.new(name, length, :padding => :zero) }

    it "should accept only :space or :zero" do
      lambda{ Slither::Column.new(name, length, :padding => :bogus) }.should raise_error(ArgumentError, "Option :padding only accepts :space (default) or :zero")
    end

    it "should override the default padding" do
      column.padding.should == :zero
    end
  end

  it "should return the proper unpack value for a string" do
    column.send(:unpacker).should == 'A5'
  end

  describe "when parsing a value from a file" do
    it "should default to a string" do
      column.parse('    name ').should == 'name'
      column.parse('      234').should == '234'
      column.parse('000000234').should == '000000234'
      column.parse('12.34').should == '12.34'
    end

    it "should support the integer type" do
      column = Slither::Column.new(:amount, 10, :type=> :integer)
      column.parse('234     ').should == 234
      column.parse('     234').should == 234
      column.parse('00000234').should == 234
      column.parse('Ryan    ').should == 0
      column.parse('00023.45').should == 23
    end

    it "should support the float type" do
      column = Slither::Column.new(:amount, 10, :type=> :float)
      column.parse('  234.45').should == 234.45
      column.parse('234.5600').should == 234.56
      column.parse('     234').should == 234.0
      column.parse('00000234').should == 234.0
      column.parse('Ryan    ').should == 0
      column.parse('00023.45').should == 23.45
    end

    it "should support the money_with_implied_decimal type" do
      column = Slither::Column.new(:amount, 10, :type=> :money_with_implied_decimal)
      column.parse('   23445').should == 234.45
    end

    it "should support the date type" do
      column = Slither::Column.new(:date, 10, :type => :date)
      dt = column.parse('2009-08-22')
      dt.should be_a(Date)
      dt.to_s.should == '2009-08-22'
    end

    it "should use the format option with date type if available" do
      column = Slither::Column.new(:date, 10, :type => :date, :format => "%m%d%Y")
      dt = column.parse('08222009')
      dt.should be_a(Date)
      dt.to_s.should == '2009-08-22'
    end
  end

  describe "when applying formatting options" do
    it "should return a proper formatter" do
      column = Slither::Column.new(name, length, :align => :left)
      column.send(:formatter).should == "%-5s"
    end

    it "should respect a right alignment" do
      column = Slither::Column.new(name, length, :align => :right)
      column.format(25).should == '   25'
    end

    it "should respect a left alignment" do
      column = Slither::Column.new(name, length, :align => :left)
      column.format(25).should == '25   '
    end

    it "should respect padding with spaces" do
      column = Slither::Column.new(name, length, :padding => :space)
      column.format(25).should == '   25'
    end

    it "should respect padding with zeros with integer types" do
      column = Slither::Column.new(name, length, :type => :integer, :padding => :zero)
      column.format(25).should == '00025'
    end

    describe "that is a float type" do
      it "should respect padding with zeros aligned right" do
        column = Slither::Column.new(name, length, :type => :float, :padding => :zero, :align => :right)
        column.format(4.45).should == '04.45'
      end

      it "should respect padding with zeros aligned left" do
        column = Slither::Column.new(name, length, :type => :float, :padding => :zero, :align => :left)
        column.format(4.45).should == '4.450'
      end
    end
  end

  describe "when formatting values for a file" do
    it "should default to a string" do
      column = Slither::Column.new(:name, 10)
      column.format('Bill').should == '      Bill'
    end

    describe "whose size is too long" do
      it "should raise an error if truncate is false" do
        value = "XX" * length
        lambda { column.format(value) }.should raise_error(
          Slither::FormattedStringExceedsLengthError,
          "The formatted value '#{value}' in column '#{name}' exceeds the allowed length of #{length} chararacters."
        )
      end

      it "should truncate from the left if truncate is true and aligned left" do
        column = Slither::Column.new(name, length, :truncate => true, :align => :left)
        column.format("This is too long").should == "This "
      end

      it "should truncate from the right if truncate is true and aligned right" do
        column = Slither::Column.new(name, length, :truncate => true, :align => :right)
        column.format("This is too long").should == " long"
      end
    end

    it "should support the integer type" do
      column = Slither::Column.new(:amount, 10, :type => :integer)
      column.format(234).should        == '       234'
      column.format('234').should      == '       234'
    end

    it "should support the float type" do
      column = Slither::Column.new(:amount, 10, :type => :float)
      column.format(234.45).should       == '    234.45'
      column.format('234.4500').should   == '    234.45'
      column.format('3').should          == '       3.0'
    end

    it "should support the float type with a format" do
      column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.3f")
      column.format(234.45).should       == '   234.450'
      column.format('234.4500').should   == '   234.450'
      column.format('3').should          == '     3.000'
    end

    it "should support the float type with a format, alignment and padding" do
      column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.2f", :align => :left, :padding => :zero)
      column.format(234.45).should       == '234.450000'
      column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.2f", :align => :right, :padding => :zero)
      column.format('234.400').should    == '0000234.40'
      column = Slither::Column.new(:amount, 10, :type => :float, :format => "%.4f", :align => :left, :padding => :space)
      column.format('3').should          == '3.0000    '
    end

    it "should support the money_with_implied_decimal type" do
      column = Slither::Column.new(:amount, 10, :type=> :money_with_implied_decimal)
      column.format(234.450).should   == "     23445"
      column.format(12.34).should     == "      1234"
    end

    it "should support the date type" do
      dt = Date.new(2009, 8, 22)
      column = Slither::Column.new(:date, 10, :type => :date)
      column.format(dt).should == '2009-08-22'
    end

    it "should support the date type with a :format" do
      dt = Date.new(2009, 8, 22)
      column = Slither::Column.new(:date, 8, :type => :date, :format => "%m%d%Y")
      column.format(dt).should == '08222009'
    end
  end

end
