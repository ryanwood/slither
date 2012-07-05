require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Parser do
  
  describe "when parsing sections" do
    before(:each) do
      @definition = Slither.define :test do |d|
        d.header do |h|
          h.trap { |line| line[0,4] == 'HEAD' }
          h.column :type, 4
          h.column :file_id, 10
        end
        d.body do |b|
          b.trap { |line| line[0,4] != 'HEAD' &&  line[0,4] != 'FOOT'}
          b.column :first, 10
          b.column :last, 10
        end
        d.footer do |f|
          f.trap { |line| line[0,4] == 'FOOT' }
          f.column :type, 4
          f.column :file_id, 10
        end     
      end
      
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
    end

    it "should add lines to the proper sections" do
      @io.string = "HEAD         1\n      Paul    Hewson\n      Dave     Evans\nFOOT         1"

      expected = {
        :header => [ {:type => "HEAD", :file_id => "1" }],
        :body => [ 
          {:first => "Paul", :last => "Hewson" },
          {:first => "Dave", :last => "Evans" }
        ],
        :footer => [ {:type => "FOOT", :file_id => "1" }]
      }      
      result = @parser.parse
      result.should == expected
    end

    it "should allow optional sections to be skipped" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @io.string = '      Paul    Hewson'

      expected = { :body => [ {:first => "Paul", :last => "Hewson" } ] }
      @parser.parse.should == expected      
    end
      
    it "should raise an error if a required section is not found" do
      @io.string = '      Ryan      Wood'

      lambda { @parser.parse }.should raise_error(Slither::RequiredSectionNotFoundError, "Required section 'header' was not found.")
    end
    
    it "should raise an error if the line is too long" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @io.string = 'abc'*20

      lambda { @parser.parse }.should raise_error(Slither::LineWrongSizeError)
    end
    
    it "should raise an error if the line is too short" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @io.string = 'abc'

      lambda { @parser.parse }.should raise_error(Slither::LineWrongSizeError)
    end
    
  end
  
  describe "when parsing by bytes" do
    before(:each) do
      @definition = Slither.define :test, :by_bytes => true do |d|
        d.body do |b|
          b.trap { true }
          b.column :first, 5
          b.column :last, 5
        end   
      end
      
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
    end
    
    it "should parse valid input with newlines at end" do
      @io.string = "abcdeABCDE\n123  987  \n\n\r\n\r\n"
      
      expected = {
        :body => [
          {:first => 'abcde', :last => 'ABCDE'},
          {:first => '123', :last => '987'}
          ]
      }
      
      @parser.parse_by_bytes.should eq(expected)
    end
    
    it 'should raise error for data with incorrect line length' do
      @io.string = "abcdefghijklmnop"
      
      lambda { @parser.parse_by_bytes }.should raise_error(Slither::LineWrongSizeError)
    end
    
    it 'should handle utf characters' do
      utf_str1 = "\xE5\x9B\xBD45"
      utf_str2 = "ab\xE5\x9B\xBD"
      @io.string = (utf_str1 + utf_str2)

      expected = {
        :body => [ {:first => utf_str1, :last => utf_str2} ]
      }
      
      @parser.parse_by_bytes.should eq(expected)
    end
    
    it 'should throw exception if section lengths are different' do
      definition = Slither.define :test, :by_bytes => true do |d|
        d.body do |b|
          b.column :one, 5
        end
        d.foot do |f|
          f.column :only, 2
        end   
      end
      
      parser = Slither::Parser.new(definition, @io)
      
      lambda { parser.parse_by_bytes }.should raise_error(Slither::SectionsNotSameLengthError)
    end
  end
  
  describe 'when calling the helper method' do
    
    it 'remove_newlines returns true for file starting in newlines or EOF' do
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
      
      @parser.send(:remove_newlines!).should eq(true)
      
      @io.string = "\nXYZ"
      @parser.send(:remove_newlines!).should eq(true)
      @io.string = "\r\n"
      @parser.send(:remove_newlines!).should eq(true)
      @io.string = "\n\n\n\nXYZ\n"
      @parser.send(:remove_newlines!).should eq(true)
      @io.string = ""
      @parser.send(:remove_newlines!).should eq(true)
      
    end
    
    it 'remove_newlines returns false for any other first characters' do
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
      
      @io.string = "XYZ\nxyz"
      @parser.send(:remove_newlines!).should eq(false)
      @io.string = " \nxyz"
      @parser.send(:remove_newlines!).should eq(false)
      @io.string = "!YZxyz\n"
      @parser.send(:remove_newlines!).should eq(false)
      
    end
    
    it 'remove_newlines leaves first non-newline char in place' do
      @io = StringIO.new 
      @parser = Slither::Parser.new(@definition, @io)
      
      @io.string = "\n\nXYZ"
      @parser.send(:remove_newlines!).should eq(true)
      @io.getc.should eq("X")
      @parser.send(:remove_newlines!).should eq(false)
    end
    
    it 'newline? it is true for \n or \r and false otherwise' do
      @parser = Slither::Parser.new(nil,nil)
      
      [["\n",true],["\r",true],["n",false]].each do |el|
        @parser.send(:newline?,el[0].ord).should eq(el[1])
      end
      @parser.send(:newline?,nil).should eq(false)
      @parser.send(:newline?,"").should eq(false)
    end
    
  end
end