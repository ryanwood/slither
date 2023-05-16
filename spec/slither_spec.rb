# frozen_string_literal: true

RSpec.describe Slither do
  subject { described_class }

  let(:name) { :doc }
  let(:options) { { align: :left } }

  describe ".define" do
    it "creates a new definition using the specified name and options" do
      definition = double("definition")

      expect(subject).to receive(:define).with(name, options).and_return(definition)

      subject.define(name, options)
    end

    it "pass the definition to the block" do
      yielded = nil

      described_class.define(name) do |y|
        yielded = y
      end

      expect(yielded).to be_a(Slither::Definition)
    end

    it "adds the definition to the internal definition count" do
      expect do
        subject.define("new_definition", options) {}
      end.to change { subject.send(:definitions).count }.by(1)
    end
  end

  describe ".generate" do
    it "should raise an error if the definition name is not found" do
      expect do
        subject.generate(:not_found_definition, {})
      end.to raise_error(ArgumentError)
    end

    it "should output a string" do
      simple_definition

      expect(
        subject.generate(:simple, simple_definition_test_data)
      ).to be_a(String)
    end
  end

  describe ".write" do
    let(:file_name) { "file.txt" }

    it "write a file" do
      simple_definition

      file = double("file")
      allow(File).to receive(:open).with(file_name, "w").and_yield(file)
      expect(file).to receive(:write)

      subject.write(file_name, :simple, simple_definition_test_data)
    end
  end

  describe ".parse" do
    let(:file_name) { "file.txt" }

    it "raise and error if the file does not exists" do
      expect do
        subject.parse(file_name, :test, {})
      end.to raise_error(ArgumentError)
    end

    context "when the file is found" do
      before do
        allow(File).to receive(:exists?).and_return(true)
      end

      context "and the definition is not found" do
        it "raises an error due to the definition name not being found" do
          expect do
            subject.parse(file_name, :test, {})
          end.to raise_error(ArgumentError)
        end
      end

      context "and the definition is found" do
        it "parse the file" do
          simple_definition

          expect(
            Slither.parse(simple_definition_file, :simple)
          ).to eq(simple_definition_test_data)
        end
      end
    end
  end
end
