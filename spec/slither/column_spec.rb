# frozen_string_literal: true

RSpec.describe Slither::Column do
  subject { described_class.new(name, length, **options) }

  let(:name) { :id }
  let(:length) { 5 }
  let(:options) { {} }

  describe "#initialize" do
    it "have a name" do
      expect(subject.name).to eq(name)
    end

    it "have a length" do
      expect(subject.length).to eq(length)
    end

    it "have a default padding" do
      expect(subject.padding).to eq(:space)
    end

    it "have a default alignment" do
      expect(subject.alignment).to eq(:right)
    end

    # WHY THO?
    it "have a default formatter" do
      expect(subject.send(:formatter)).to eq("%5s")
    end

    it "have a default unpacker value" do
      expect(subject.send(:unpacker)).to eq("A5")
    end

    context "when specifying an alignment" do
      let(:options) { { align: alignment } }
      let(:alignment) { :left }

      it "override the default one" do
        expect(subject.alignment).to eq(alignment)
      end

      context "when alignment is not left nor right" do
        let(:alignment) { :up }

        it "raises error" do
          expect do
            subject
          end.to raise_error(ArgumentError)
        end
      end
    end

    context "when specifying padding" do
      let(:options) { { padding: } }
      let(:padding) { :zero }

      it "override the default one" do
        expect(subject.padding).to eq(padding)
      end

      context "when padding is not space nor zero" do
        let(:padding) { :up }

        it "raises error" do
          expect do
            subject
          end.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#parse" do
    context "when using the default (string) type" do
      let(:parse_collection) do
        [
          { value: "    name ", result: "name" },
          { value: "      234", result: "234" },
          { value: "000000234", result: "000000234" },
          { value: "12.34", result: "12.34" }
        ]
      end

      it "parse the expected values" do
        parse_collection.each do |to_parse|
          expect(subject.parse(to_parse[:value])).to eq(to_parse[:result])
        end
      end
    end

    context "when type is integer" do
      let(:options) { { type: :integer } }

      let(:parse_collection) do
        [
          { value: "234     ", result: 234 },
          { value: "     234", result: 234 },
          { value: "00000234", result: 234 },
          { value: "Ryan    ", result: 0 },
          { value: "00023.45", result: 23 }
        ]
      end

      it "parse the expected values" do
        parse_collection.each do |to_parse|
          expect(subject.parse(to_parse[:value])).to eq(to_parse[:result])
        end
      end
    end

    context "when type is float" do
      let(:options) { { type: :float } }

      let(:parse_collection) do
        [
          { value: "  234.45", result: 234.45 },
          { value: "234.5600", result: 234.56 },
          { value: "     234", result: 234.0 },
          { value: "00000234", result: 234.0 },
          { value: "Ryan    ", result: 0 },
          { value: "00023.45", result: 23.45 }
        ]
      end

      it "parse the expected values" do
        parse_collection.each do |to_parse|
          expect(subject.parse(to_parse[:value])).to eq(to_parse[:result])
        end
      end
    end

    context "when type is money_with_implied_decimal" do
      let(:options) { { type: :money_with_implied_decimal } }

      it "parse the expected value" do
        expect(subject.parse("   23445")).to eq(234.45)
      end
    end

    context "when type is date" do
      let(:options) { { type: :date } }

      it "parse the expected value" do
        date = "2023-03-10"

        result = subject.parse(date)

        expect(result).to be_a(Date)
        expect(result.to_s).to eq(date)
      end

      context "and date format is specified" do
        let(:options) { { type: :date, format: "%m%d%Y" } }

        it "parse the expected value" do
          date = "03102023"

          result = subject.parse(date)

          expect(result).to be_a(Date)
          expect(result.to_s).to eq("2023-03-10")
        end
      end
    end
  end

  describe "#format" do
    context "when applying formatting options" do
      context "using left alignment" do
        let(:options) { { align: :left } }

        it "uses a proper formatter" do
          expect(subject.send(:formatter)).to eq("%-5s")
        end

        it "respect the format" do
          expect(subject.format(25)).to eq("25   ")
        end
      end

      context "using right alignment" do
        let(:options) { { align: :right } }

        it "respect the format" do
          expect(subject.format(25)).to eq("   25")
        end
      end

      context "using padding with spaces" do
        let(:options) { { padding: :space } }

        it "respect the format" do
          expect(subject.format(25)).to eq("   25")
        end
      end

      context "using padding with zeros with integer types" do
        let(:options) { { type: :integer, padding: :zero } }

        it "respect the format" do
          expect(subject.format(25)).to eq("00025")
        end
      end

      context "using padding with zeros with float type" do
        let(:options) { { type: :float, padding: :zero, align: } }

        context "right aligned" do
          let(:align) { :right }

          it "respect the format" do
            expect(subject.format(4.45)).to eq("04.45")
          end
        end

        context "left aligned" do
          let(:align) { :left }

          it "respect the format" do
            expect(subject.format(4.45)).to eq("4.450")
          end
        end
      end
    end

    context "when formatting files/strings" do
      it "parse the string" do
        expect(subject.format("Bill")).to eq(" Bill")
      end

      context "when string is too long" do
        it "raises an error" do
          value = "Billllllllllll"

          expect do
            subject.format(value)
          end.to raise_error(Slither::FormattedStringExceedsLengthError)
        end
      end

      context "truncate is true" do
        let(:options) { { truncate: true, align: } }
        let(:value) { "This is too long" }

        context "left aligned" do
          let(:align) { :left }

          it "truncate the string left-aligned" do
            expect(subject.format(value)).to eq("This ")
          end
        end

        context "right aligned" do
          let(:align) { :right }

          it "truncate the string right-aligned" do
            expect(subject.format(value)).to eq(" long")
          end
        end
      end

      context "when type is integer" do
        let(:options) { { type: :integer } }

        it "supports the type" do
          expect(subject.format(234)).to eq("  234")
          expect(subject.format("234")).to eq("  234")
        end
      end

      context "when type is float" do
        let(:options) { { type: :float } }

        it "supports the type" do
          expect(subject.format(23.4)).to eq(" 23.4")
          expect(subject.format("2.2000")).to eq("  2.2")
          expect(subject.format("3")).to eq("  3.0")
        end

        context "with format" do
          let(:options) { { type: :float, format: "%.3f" } }
          let(:length) { 10 }

          it "support the type with its format" do
            expect(subject.format(234.45)).to eq("   234.450")
            expect(subject.format("234.4500")).to eq("   234.450")
            expect(subject.format("3")).to eq("     3.000")
          end

          context "alignment and padding" do
            it "supports the type with the extra options" do
              [
                { format: "%.2f", aligment: :left, padding: :zero, value: 234.45, result: "234.450000" },
                { format: "%.2f", aligment: :right, padding: :zero, value: "234.400", result: "0000234.40" },
                { format: "%.4f", aligment: :left, padding: :space, value: "3", result: "3.0000    " }
              ].each do |obj|
                sub = described_class.new(
                  :amount,
                  10,
                  type: :float,
                  format: obj[:format],
                  align: obj[:aligment],
                  padding: obj[:padding]
                )

                expect(sub.format(obj[:value])).to eq(obj[:result])
              end
            end
          end
        end
      end

      context "when type is money_with_implied_decimal" do
        let(:options) { { type: :money_with_implied_decimal } }
        let(:length) { 10 }

        it "supports the type" do
          expect(subject.format(234.450)).to eq("     23445")
          expect(subject.format(12.34)).to eq("      1234")
        end
      end

      context "when type is date" do
        let(:options) { { type: :date, **extra_opts } }
        let(:extra_opts) { {} }
        let(:length) { 10 }
        let(:date) { Date.new(2009, 8, 22) }

        it "supports the type" do
          expect(subject.format(date)).to eq("2009-08-22")
        end

        context "and format is specified" do
          let(:extra_opts) { { format: "%m%d%Y" } }

          it "supports the type with its format" do
            expect(subject.format(date)).to eq("  08222009")
          end
        end
      end
    end
  end
end
