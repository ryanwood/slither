require File.join(File.dirname(__FILE__), 'spec_helper')

describe Slither::Definition do
  
  before(:each) do
    @options = { :align => :left }
  end
  
  it "should create and yield a new section object" do
    yielded = nil
    definition = Slither::Definition.new
    definition.section :header do |section|
      yielded = section
    end
    yielded.should be_a(Slither::Section)
    definition.sections.first.should == yielded
  end
  
  it "should not create duplicate section names" do
    d = Slither::Definition.new
    lambda { d.section(:header){ } }.should_not raise_error(ArgumentError)
    lambda { d.section(:header){ } }.should raise_error(ArgumentError)
  end

  it "can specify an alignment" do
    d = Slither::Definition.new :align => :right
    d.options[:align].should == :right
  end

  it "should override the default if :align is passed to the section" do
    Slither::Section.should_receive(:new).with('name', {:align => :left})
    d = Slither::Definition.new
    d.options[:align].should == :right
    d.section('name', :align => :left){}
  end
  
end