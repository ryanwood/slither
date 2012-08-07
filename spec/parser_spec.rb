require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Parser do
  before(:each) do
    @definition = mock('definition', :sections => [])
    @file = mock("file", :gets => nil)
    @file_name = 'test.txt'
    @parser = Slither::Parser.new(@definition, @file_name)
  end
  
  it "should open and yield the source file" do
    File.should_receive(:open).with(@file_name, 'r').and_yield(@file)
    @parser.parse
  end
  
  describe "when parsing sections" do
    before(:each) do
      @definition = Slither.define :test do |d|
        d.header do |h|
          h.trap { |line| line[0,4] == 'HEAD' }
          h.column :type, 4
          h.column :file_id, 10
        end
        d.body do |b|
          b.trap { |line| line[0,4] =~ /[^(HEAD|FOOT)]/ }
          b.column :first, 10
          b.column :last, 10
        end
        d.footer do |f|
          f.trap { |line| line[0,4] == 'FOOT' }
          f.column :type, 4
          f.column :file_id, 10
        end     
      end
      File.should_receive(:open).with(@file_name, 'r').and_yield(@file)
      @parser = Slither::Parser.new(@definition, @file_name)
    end

    it "should add lines to the proper sections" do
      @file.should_receive(:gets).exactly(4).times.and_return(
        'HEAD         1',
        '      Paul    Hewson',
        '      Dave     Evans',
        'FOOT         1',
        nil
      )
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
      @file.should_receive(:gets).twice.and_return('      Paul    Hewson', nil)
      expected = { :body => [ {:first => "Paul", :last => "Hewson" } ] }
      @parser.parse.should == expected      
    end
      
    it "should raise an error if a required section is not found" do
      @file.should_receive(:gets).twice.and_return('      Ryan      Wood', nil)
      lambda { @parser.parse }.should raise_error(Slither::RequiredSectionNotFoundError, "Required section 'header' was not found.")
    end
    
    # it "raise an error if a section limit is over run"
  end

  describe "when repeating sections" do
    before(:each) do
      @repeat_file_name = 'repeat.txt'
    end

    before(:all) do
      @repeat_definition = Slither.define :simple, :repeater => 'r' do |d|
        d.header do |header|
          header.trap { |line| line[0] == '1' }
          header.column :header_begin, 1
          header.column :batch_number, 3, :padding => :zero
        end
        d.data :repeatable => true do |data|
          data.trap { |line| line[0] == '2' }
          data.column :data_begin, 1
          data.column :record_number, 3
          data.column :record_number_plus_batch, 6
          data.column :id, 2
          data.column :name, 10, :align => :left
        end
        d.tail_record :repeatable => true do |tail_record|
          tail_record.trap { |line| line[0] == '3' }
          tail_record.column :tail_record_begin, 1
          tail_record.column :num_records, 3
        end
        d.footer do |footer|
          footer.trap { |line| line[0] == '4' }
          footer.column :footer_record_begin, 1
          footer.column :total_record_count, 3
          footer.column :batch_number, 3, :padding => :zero
        end
      end

      File.open('repeat.txt', 'w') {|f| f.write("1001\n200100100101Russell   \n200200200102John      \n3002\n200100100101Bill      \n3001\n4003001") }
      @repeat_parser = Slither::Parser.new(@repeat_definition, 'repeat.txt')
    end

    it "should create hash keys based on repeated sections" do
      expected = {
          :header => [ {:header_begin => '1', :batch_number => '001' }],
          :datar1 => [
              {:data_begin => "2", :record_number => '001',
               :record_number_plus_batch => '001001', :id => '01', :name => 'Russell'  },
              {:data_begin => "2", :record_number => '002',
               :record_number_plus_batch => '002001', :id => '02', :name => 'John'  },
          ],
          :tail_recordr2 => [:tail_record_begin => '3', :num_records => '002'],
          :datar3 => [
              {:data_begin => "2", :record_number => '001',
               :record_number_plus_batch => '001001', :id => '01', :name => 'Bill'  }
          ],
          :tail_recordr4 => [:tail_record_begin => '3', :num_records => '001'],
          :footer => [ {:footer_record_begin => '4', :total_record_count => "003", :batch_number => '001' }]
      }
      result = @repeat_parser.parse
      result.should == expected
    end

    after(:all) do
      File.delete('repeat.txt')
    end

  end
end