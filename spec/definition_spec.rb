require 'slither'

describe Slither::Definition do

  describe "when specifying alignment" do
    it "should have an alignment option" do
      definition = Slither::Definition.new :align => :right
      definition.options[:align].should == :right
    end

    it "should default to being right aligned" do
      definition = Slither::Definition.new
      definition.options[:align].should == :right
    end

    it "should override the default if :align is passed to the section" do
      section = double('section').as_null_object
      Slither::Section.should_receive(:new).with('name', {:align => :left}).and_return(section)
      definition = Slither::Definition.new
      definition.options[:align].should == :right
      definition.section('name', :align => :left) {}
    end
  end

  describe "when creating a section" do
    let(:definition) { Slither::Definition.new }
    let(:section) { double('section').as_null_object }

    it "should create and yield a new section object" do
      yielded = nil
      definition.section :header do |s|
        yielded = s
      end
      yielded.should be_a(Slither::Section)
      definition.sections.first.should == yielded
    end

    it "should magically build a section from an unknown method" do
      Slither::Section.should_receive(:new).with(:header, anything()).and_return(section)
      definition.header {}
    end

    it "should not create duplicate section names" do
      lambda { definition.section(:header) {} }.should_not raise_error(ArgumentError)
      lambda { definition.section(:header) {} }.should raise_error(ArgumentError, "Reserved or duplicate section name: 'header'")
    end

    it "should throw an error if a reserved section name is used" do
      lambda { definition.section(:spacer) {} }.should raise_error(ArgumentError, "Reserved or duplicate section name: 'spacer'")
    end
  end

  describe "when creating a template" do
    let(:definition) { Slither::Definition.new }
    let(:section) { double('section').as_null_object }

    it "should create a new section" do
      Slither::Section.should_receive(:new).with(:row, anything()).and_return(@section)
      definition.template(:row) {}
    end

    it "should yield the new section" do
      Slither::Section.should_receive(:new).with(:row, anything()).and_return(@section)
      yielded = nil
      definition.template :row do |section|
        yielded = section
      end
      yielded.should == @section
    end

    it "add a section to the templates collection" do
      definition.should have(0).templates
      definition.template :row do |t|
        t.column :id, 3
      end
      definition.should have(1).templates
    end
  end
end
