require 'slither'

describe Slither do

  let(:name) { :doc }
  let(:options) { Hash.new( :align => :left ) }

  describe "when defining a format" do
    let(:definition) { double('definition') }

    it "should create a new definition using the specified name and options" do
      Slither.should_receive(:define).with(name, options).and_return(definition)
      Slither.define(name , options)
    end

    it "should pass the definition to the block" do
      yielded = nil
      Slither.define(name) do |y|
        yielded = y
      end
      yielded.should be_a( Slither::Definition )
    end

    it "should add to the internal definition count" do
      Slither.definitions.clear
      Slither.should have(0).definitions
      Slither.define(name , options) {}
      Slither.should have(1).definitions
    end
  end

  describe "when creating file from data" do
    it "should raise an error if the definition name is not found" do
      lambda { Slither.generate(:not_there, {}) }.should raise_error(ArgumentError)
    end

    it "should output a string" do
      definition = double('definition')
      generator = double('generator')
      generator.should_receive(:generate).with({})
      Slither.should_receive(:definition).with(:test).and_return(definition)
      Slither::Generator.should_receive(:new).with(definition).and_return(generator)
      Slither.generate(:test, {})
    end

    it "should output a file" do
      file = double('file')
      text = double('string')
      file.should_receive(:write).with(text)
      File.should_receive(:open).with('file.txt', 'w').and_yield(file)
      Slither.should_receive(:generate).with(:test, {}).and_return(text)
      Slither.write('file.txt', :test, {})
    end
  end

  describe "when parsing a file" do
    let(:file_name) { 'file.txt' }

    it "should check the file exists" do
      lambda { Slither.parse(file_name, :test, {}) }.should raise_error(ArgumentError)
    end

    it "should raise an error if the definition name is not found" do
      Slither.definitions.clear
      File.stub!(:exists? => true)
      lambda { Slither.parse(file_name, :test, {}) }.should raise_error(ArgumentError)
    end

    it "should create a parser and call parse" do
      File.stub!(:exists? => true)
      parser = double("parser").as_null_object
      definition = double('definition')
      Slither.should_receive(:definition).with(:test).and_return(definition)
      Slither::Parser.should_receive(:new).with(definition, file_name).and_return(parser)
      Slither.parse(file_name, :test)
    end
  end
end
