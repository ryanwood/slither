require File.join(File.dirname(__FILE__), 'spec_helper')
    
describe Slither::Generator do
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
    @data = {
      :header => [ {:type => "HEAD", :file_id => "1" }],
      :body => [ 
        {:first => "Paul", :last => "Hewson" },
        {:first => "Dave", :last => "Evans" }
      ],
      :footer => [ {:type => "FOOT", :file_id => "1" }]
    }   
    @generator = Slither::Generator.new(@definition)
  end
  
  it "should raise an error if there is no data for a required section" do
    @data.delete :header
    lambda {  @generator.generate(@data) }.should raise_error(Slither::RequiredSectionEmptyError, "Required section 'header' was empty.")
  end
  
  it "should generate a string" do
    expected = "HEAD         1\n      Paul    Hewson\n      Dave     Evans\nFOOT         1"
    @generator.generate(@data).should == expected
  end

  describe "when repeating sections" do
    before(:all) do
      @repeat_definition = Slither.define :simple, :repeater => 'r' do |d|
        d.header do |header|
          header.trap { |line| line[0,1] == 1 }
          header.column :header_begin, 1
          header.column :batch_number, 3, :padding => :zero
        end
        d.data :repeatable => true do |data|
          data.trap { |line| line[0,1] == 2 }
          data.column :data_begin, 1
          data.column :record_number, 3
          data.column :record_number_plus_batch, 6
          data.column :id, 2
          data.column :name, 10, :align => :left
        end
        d.tail_record :repeatable => true do |tail_record|
          tail_record.trap { |line| line[0,1] == 3 }
          tail_record.column :tail_record_begin, 1
          tail_record.column :num_records, 3
        end
        d.footer do |footer|
          footer.trap { |line| line[0,1] == 4 }
          footer.column :footer_record_begin, 1
          footer.column :total_record_count, 3
          footer.column :batch_number, 3, :padding => :zero
        end
      end
      @repeat_data = {
          :header => [ {:header_begin => 1, :batch_number => 001 }],
          :datar1 => [
              {:data_begin => 2, :record_number => '001',
               :record_number_plus_batch => '001001', :id => '01', :name => 'Russell'  },
              {:data_begin => 2, :record_number => '002',
               :record_number_plus_batch => '002001', :id => '02', :name => 'John'  },
          ],
          :tail_recordr1 => [:tail_record_begin => 3, :num_records => '002'],
          :datar2 => [
              {:data_begin => 2, :record_number => '001',
               :record_number_plus_batch => '001001', :id => '01', :name => 'Bill'  }
          ],
          :tail_recordr2 => [:tail_record_begin => 3, :num_records => '001'],
          :footer => [ {:footer_record_begin => 4, :total_record_count => "003", :batch_number => '001' }]
      }
      @repeat_generator = Slither::Generator.new(@repeat_definition)
    end

    it "should generate a string" do
      expected = "1001\n200100100101Russell   \n200200200102John      \n3002\n200100100101Bill      \n3001\n4003001"
      @repeat_generator.generate(@repeat_data).should == expected
    end
  end
end