# rubocop:disable Style/FrozenStringLiteralComment

RSpec.describe Slither::Parser do
  subject { described_class.new(definition, io) }

  let(:io) { StringIO.new }

  let(:definition) do
    Slither.define :test, by_bytes: false do |d|
      d.section(:header) do |h|
        h.trap { |line| line[0, 4] == "HEAD" }
        h.column :type, 4
        h.column :file_id, 10
      end

      d.section(:body) do |b|
        b.trap { |line| line[0, 4] != "HEAD" && line[0, 4] != "FOOT" }
        b.column :first, 10
        b.column :last, 10
      end

      d.section(:footer) do |f|
        f.trap { |line| line[0, 4] == "FOOT" }
        f.column :type, 4
        f.column :file_id, 10
      end
    end
  end

  describe "parse" do
    it "parse the file correctly" do
      io.string = "HEAD         1\n      Paul    Hewson\n      Dave     Evans\nFOOT         1"

      expected = {
        header: [{ type: "HEAD", file_id: "1" }],
        body: [
          { first: "Paul", last: "Hewson" },
          { first: "Dave", last: "Evans" }
        ],
        footer: [{ type: "FOOT", file_id: "1" }]
      }

      expect(subject.parse).to eq(expected)
    end

    it "raise an error if a required section is not found" do
      io.string = "      Ryan      Wood"

      expect do
        subject.parse
      end.to raise_error(Slither::RequiredSectionNotFoundError)
    end

    context "when optional sections are skipped" do
      before do
        definition.sections[0].optional = true
        definition.sections[2].optional = true
      end

      it "allow optional sections to be skipped" do
        io.string = "      Paul    Hewson"

        expected = { body: [{ first: "Paul", last: "Hewson" }] }

        expect(subject.parse).to eq(expected)
      end

      it "raise an error if the line is too long" do
        io.string = "abc" * 50

        expect do
          subject.parse
        end.to raise_error(Slither::LineWrongSizeError)
      end

      it "raise an error if the line is too short" do
        io.string = "abc"

        expect do
          subject.parse
        end.to raise_error(Slither::LineWrongSizeError)
      end
    end
  end

  describe "parse_by_bytes" do
    let(:definition) do
      Slither.define :test, by_bytes: true do |d|
        d.body do |b|
          b.trap { true }
          b.column :first, 5
          b.column :last, 5
        end
      end
    end

    it "parse the file correctly" do
      io.string = "meep last \nmoop last "

      expected = {
        body: [
          { first: "meep", last: "last" },
          { first: "moop", last: "last" }
        ]
      }

      expect(subject.parse_by_bytes).to eq(expected)
    end

    it "handle UTF characters" do
      utf_str1 = "\xE5\x9B\xBD45"
      utf_str2 = "ab\xE5\x9B\xBD"

      io.string = utf_str1 + utf_str2

      encoding = Encoding::ASCII_8BIT

      expected = {
        body: [
          {
            first: utf_str1.force_encoding(encoding),
            last: utf_str2.force_encoding(encoding)
          }
        ]
      }

      # NOTE: the result is returned as ASCII_8BIT whereas utf_str1 and 2 are returned
      #       as UTF-8 thus the strings are different.
      expect(subject.parse_by_bytes).to eq(expected)
    end

    it "handle mid-line newline chars" do
      str1 = "12\n45"
      str2 = "a\n\r\nb"

      io.string = ("#{str1}#{str2}\n#{str1}#{str2}")

      expected = {
        body: [{ first: str1, last: str2 }, { first: str1, last: str2 }]
      }

      expect(subject.parse_by_bytes).to eq(expected)
    end

    context "when file is invalid" do
      it "raise error if the line is too long" do
        io.string = "meeptoolongg \n meeptolooongagain"

        expect do
          subject.parse_by_bytes
        end.to raise_error(Slither::LineWrongSizeError)
      end

      it "raise error if the line is too short" do
        io.string = "abc"

        expect do
          subject.parse_by_bytes
        end.to raise_error(Slither::LineWrongSizeError)
      end

      it "raise error if the line contain empty lines" do
        io.string = "abcdefghij\r\n\n\n\n" # 10 then 3

        expect do
          subject.parse_by_bytes
        end.to raise_error(Slither::LineWrongSizeError)
      end

      context "section lengths are different" do
        let(:definition) do
          Slither.define :test, by_bytes: true do |d|
            d.body do |b|
              b.column :one, 5
            end

            d.foot do |f|
              f.column :only, 2
            end
          end
        end

        it "raise an error" do
          expect do
            subject.parse_by_bytes
          end.to raise_error(Slither::SectionsNotSameLengthError)
        end
      end
    end
  end

  describe "private methods" do
    describe "#remove_new_lines!" do
      it "returns true for file starting in newlines or EOF" do
        expect(subject.send(:remove_newlines!)).to eq(true)

        io.string = "\nXYZ"
        expect(subject.send(:remove_newlines!)).to eq(true)

        io.string = "\r\n"
        expect(subject.send(:remove_newlines!)).to eq(true)

        io.string = "\n\n\n\nXYZ\n"
        expect(subject.send(:remove_newlines!)).to eq(true)

        io.string = ""
        expect(subject.send(:remove_newlines!)).to eq(true)
      end

      it "return false for any other first characters" do
        io.string = "XYZ\nxyz"
        expect(subject.send(:remove_newlines!)).to eq(false)

        io.string = " \nxyz"
        expect(subject.send(:remove_newlines!)).to eq(false)

        io.string = "!YZxyz\n"
        expect(subject.send(:remove_newlines!)).to eq(false)
      end

      it "leaves first non-newline char in place" do
        io.string = "\nXYZ"
        expect(subject.send(:remove_newlines!)).to eq(true)

        first_character = io.getc
        expect(first_character).to eq("X")

        expect(subject.send(:remove_newlines!)).to eq(false)
      end
    end

    describe "#newline?" do
      it "is true for \n or \r and false otherwise" do
        ["\n", "\r"].each do |e|
          # ord = https://apidock.com/rails/String/ord
          expect(subject.send(:newline?, e.ord)).to eq(true)
        end

        ["", nil, "meep"].each do |e|
          expect(subject.send(:newline?, e)).to eq(false)
        end
      end
    end
  end
end

# rubocop:enable Style/FrozenStringLiteralComment
