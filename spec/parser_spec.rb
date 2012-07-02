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
          #b.trap { |line| line[0,4] == '    ' }
          b.column :first, 10
          b.column :last, 10
        end
        d.footer do |f|
          f.trap { |line| line[0,4] == 'FOOT' }
          f.column :type, 4
          f.column :file_id, 10
        end     
      end
      
      @file_io = double("IO")
      @parser = Slither::Parser.new(@definition, @file_io)
    end

    it "should add lines to the proper sections" do
      @file_io.should_receive(:each_line).
        and_yield('HEAD         1').and_yield('      Paul    Hewson').
        and_yield('      Dave     Evans').and_yield('FOOT         1').and_yield(nil)
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
      @file_io.stub(:each_line).and_yield('      Paul    Hewson').and_yield(nil)
      expected = { :body => [ {:first => "Paul", :last => "Hewson" } ] }
      @parser.parse.should == expected      
    end
      
    it "should raise an error if a required section is not found" do
      @file_io.stub(:each_line).and_yield('      Ryan      Wood').and_yield(nil)
      lambda { @parser.parse }.should raise_error(Slither::RequiredSectionNotFoundError, "Required section 'header' was not found.")
    end
    
    it "should raise an error if the line is too long" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @file_io.stub(:each_line).and_yield('abc'*20).and_yield(nil)
      lambda { @parser.parse }.should raise_error(Slither::LineTooLongError)
    end
    
    it "should raise an error if the line is too short" do
      @definition.sections[0].optional = true
      @definition.sections[2].optional = true
      @file_io.stub(:each_line).and_yield('abc').and_yield(nil)
      lambda { @parser.parse }.should raise_error(Slither::LineTooShortError)
    end
    
    
    # it "raise an error if a section limit is over run"
  end
end