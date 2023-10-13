# frozen_string_literal: true

RSpec.describe Slither::Section do
  subject { described_class.new(:body) }

  describe "#initialize" do
    it "have no columns after creation" do
      expect(subject.columns).to be_empty
    end

    it "know its reserved names" do
      reserved_names = [:spacer]

      reserved_names.each do |name|
        expect(Slither::Section::RESERVED_NAMES).to include(name)
      end
    end

    context "when specifying the alignment" do
      subject { described_class.new(:name, align: alignment) }

      let(:alignment) { :left }

      it "is overriden" do
        expect(subject.options[:align]).to eq(alignment)
      end
    end
  end

  describe "#column" do
    it "prevent duplicate column names" do
      subject.column(:id, 10)

      expect do
        subject.column(:id, 10)
      end.to raise_error(Slither::DuplicateColumnNameError)
    end

    it "should allow duplicate column names that are reserved (i.e. spacer)" do
      subject.spacer(10)

      expect do
        subject.spacer(10)
        subject.spacer(5)
      end.not_to raise_error
    end

    context "when building many columns" do
      it "build an ordered column list" do
        columns = [
          subject.column(:id, 10),
          subject.column(:name, 30),
          subject.column(:state, 2)
        ]

        expect(subject.columns).to match(columns)
      end
    end

    context "when using a method that's not defined" do
      it "uses method_missing to create a column" do
        column = subject.first_name(5)

        expect(subject.columns).to match([column])
      end
    end
  end

  describe "#spacer" do
    it "create spacer columns" do
      spacer_column = subject.spacer(5)

      expect(subject.columns).to match([spacer_column])
    end
  end

  describe "#trap" do
    context "when trap is a block" do
      it "accept and store the trap" do
        subject.trap { |v| v == 4 }

        trap = subject.instance_variable_get(:@trap)

        expect(trap).to be_a(Proc)
        expect(trap.call(4)).to eq(true)
      end
    end

    it "should try to match a line using the trap" do
      subject.trap { |line| line == "hello" }

      expect(subject.match("hello")).to eq(true)
      expect(subject.match("goodbye")).to eq(false)
    end
  end

  describe "#template" do
    before do
      subject.definition = Slither::Definition.new
    end

    context "when template does not exist" do
      it "raise an error if the template is not found on the definition" do
        expect do
          subject.template(:none).to raise_error(ArgumentError)
        end
      end
    end

    context "when template does exist" do
      subject { described_class.new(:body, align: subject_alignment) }

      let(:subject_alignment) { :left }

      before do
        subject.definition.template(:test, align: :right) do |template|
          template.column(:first, 10)
        end
      end

      it "add the template columns to the current column list" do
        subject.template(:test)

        expect(subject.columns.size).to eq(1)
      end

      it "merge the template options with the ones on the section" do
        expect(subject.definition.options[:align]).to eq(:right)

        subject.template(:test)

        expect(subject.definition.options[:align]).to eq(:right)
        expect(subject.options[:align]).to eq(subject_alignment)
      end
    end
  end

  describe "#format" do
    let(:data) { { id: 3, name: "Ryan"} }

    it "transform the 'data' hash to the expected format based on the columns width" do
      subject.column(:id, 5)
      subject.column(:name, 10)

      data_hash_content_with_15_width = "    3      Ryan"

      expect(subject.format(data)).to eq(data_hash_content_with_15_width)
    end

    context "when a column is aligned left" do
      it "format and aligns the expected columns to the left" do
        subject.column(:id, 5)
        subject.column(:name, 10, align: :left)

        data_hash_content_with_15_width_left_aligned = "    3Ryan      "
        expect(subject.format(data)).to eq(data_hash_content_with_15_width_left_aligned)
      end
    end

    # TODO: legacy test that has been commented by some reason
    # it "should raise an error if the data and column definitions aren't the same size" do
    #   @section.column(:id, 5)
    #   lambda { @section.format(@data) }.should raise_error(
    #     Slither::ColumnMismatchError,
    #     "The 'body' section has 1 column(s) defined, but there are 2 column(s) provided in the data."
    #   )
    # end
  end

  describe "#parse" do
    let(:line) { "   45      Ryan      WoodSC " }
    let(:columns) do
      { id: 5, first: 10, last: 10, state: 2 }
    end
    let(:expected_result) do
      { id: "45", first: "Ryan", last: "Wood", state: "SC" }
    end

    before do
      columns.each do |key, value|
        subject.column(key, value)
      end
    end

    it "parse the line" do
      expect(subject.parse(line)).to eq(expected_result)
    end

    context "when section have a column with a reserved name" do
      before do
        subject.spacer(5)
      end

      it "do not return a key for reserved names" do
        expect(subject.columns.size).to eq(5)

        expect(subject.parse(line)).to eq(expected_result)
      end
    end
  end


end
