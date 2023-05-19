# frozen_string_literal: true

RSpec.describe Slither::Definition do
  describe "when specifying alignment" do
    subject { described_class }

    it "have an alignment option" do
      definition = subject.new(align: :left)

      expect(definition.options[:align]).to eq(:left)
    end

    it "default to being right aligned" do
      definition = subject.new

      expect(definition.options[:align]).to eq(:right)
    end

    context "when messing with the section alignment" do
      subject { described_class.new }

      it "defaults to :right if is not specified" do
        subject.section("name") {}

        section = subject.sections.first

        expect(section.options[:align]).to eq(:right)
      end

      it "override default if :align is passed to the section" do
        subject.section("name", align: :left) {}

        section = subject.sections.first

        expect(section.options[:align]).to eq(:left)
      end
    end
  end

  describe "#section" do
    subject { described_class.new }

    it "create and yield a new section object" do
      yielded = nil

      subject.section :header do |section|
        yielded = section
      end

      expect(yielded).to be_a(Slither::Section)
      expect(subject.sections.first).to eq(yielded)
    end

    it "magically build a section from an unknown method" do
      new_section = nil

      subject.new_section do |section|
        new_section = section
      end

      expect(new_section).to be_a(Slither::Section)
      expect(new_section.name).to eq(:new_section)
    end

    it "does not create duplicate section names" do
      subject.section(:header) {}

      expect do
        subject.section(:header) {}
      end.to raise_error(ArgumentError)
    end

    it "throw an error if a reserved section name is used" do
      reserved_name = Slither::Section::RESERVED_NAMES.first

      expect do
        subject.section(reserved_name)
      end.to raise_error(ArgumentError)
    end
  end

  describe "#template" do
    subject { described_class.new }

    it "create a new section" do
      expect(Slither::Section).to receive(:new)

      subject.template(:row) {}
    end

    it "add a section to the templates collection" do
      expect do
        subject.template(:row) {}
      end.to change { subject.templates.count }.by(1)
    end

    it "yield the new section" do
      yielded = nil

      subject.template(:row) do |section|
        yielded = section
      end

      expect(yielded).to be_a(Slither::Section)
    end
  end
end
