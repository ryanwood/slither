require File.join(File.dirname(__FILE__), 'spec_helper')

describe Slither::Definition do
  before(:each) do
  end

  describe "when specifying alignment" do
    it "should have an alignment option" do
      d = Slither::Definition.new :align => :right
      d.options[:align].should == :right
    end

    it "should default to being right aligned" do
      d = Slither::Definition.new
      d.options[:align].should == :right
    end

    it "should override the default if :align is passed to the section" do
      section = mock('section', :null_object => true)
      Slither::Section.should_receive(:new).with('name', {:align => :left}).and_return(section)
      d = Slither::Definition.new
      d.options[:align].should == :right
      d.section('name', :align => :left) {}
    end
  end

  describe "when creating a section" do
    before(:each) do
      @d = Slither::Definition.new
      @section = mock('section', :null_object => true)
    end

    it "should create and yield a new section object" do
      yielded = nil
      @d.section :header do |section|
        yielded = section
      end
      yielded.should be_a(Slither::Section)
      @d.sections.first.should == yielded
    end

    it "should magically build a section from an unknown method" do
      Slither::Section.should_receive(:new).with(:header, anything()).and_return(@section)
      @d.header {}
    end

    it "should not create duplicate section names" do
      lambda { @d.section(:header) {} }.should_not raise_error(ArgumentError)
      lambda { @d.section(:header) {} }.should raise_error(ArgumentError, "Reserved or duplicate section name: 'header'")
    end

    it "should throw an error if a reserved section name is used" do
      lambda { @d.section(:spacer) {} }.should raise_error(ArgumentError, "Reserved or duplicate section name: 'spacer'")
    end
  end

  describe "when creating a template" do
    before(:each) do
      @d = Slither::Definition.new
      @section = mock('section', :null_object => true)
    end

    it "should create a new section" do
      Slither::Section.should_receive(:new).with(:row, anything()).and_return(@section)
      @d.template(:row) {}
    end

    it "should yield the new section" do
      Slither::Section.should_receive(:new).with(:row, anything()).and_return(@section)
      yielded = nil
      @d.template :row do |section|
        yielded = section
      end
      yielded.should == @section
    end

    it "add a section to the templates collection" do
      @d.should have(0).templates
      @d.template :row do |t|
        t.column :id, 3
      end
      @d.should have(1).templates
    end
  end
end
