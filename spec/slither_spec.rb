require File.join(File.dirname(__FILE__), 'spec_helper')

describe Slither do
  
  before(:each) do
    @name = :doc
    @options = { :align => :left }
  end
  
  describe "when defining a format" do
    before(:each) do
      @definition = mock('definition')
    end
  
    it "should create a new definition using the specified name and options" do
      Slither.should_receive(:define).with(@name, @options).and_return(@definition)
      Slither.define(@name , @options)
    end
    
    it "should pass the definition to the block" do
      yielded = nil
      Slither.define(@name) do |y|
        yielded = y
      end
      yielded.should be_a( Slither::Definition )
    end    
  end
  
	describe "when generating a string" do

	end
	
	describe "when writing a file" do
		
	end

end
