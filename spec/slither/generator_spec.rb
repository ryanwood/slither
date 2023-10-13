# frozen_string_literal: true

RSpec.describe Slither::Generator do
  subject { described_class.new(definition) }

  let(:definition) do
    Slither.define :test do |d|
      d.header do |h|
        h.trap { |line| line[0,4] == 'HEAD' }
        h.column :type, 4
        h.column :file_id, 10
      end

      d.body do |b|
        b.trap { |line| line[0,4] =~ /[^(HEAD|FOOT)]/ }
        b.column :first, 10
        b.column :last, 10
      end

      d.footer do |f|
        f.trap { |line| line[0,4] == 'FOOT' }
        f.column :type, 4
        f.column :file_id, 10
      end
    end
  end

  describe ".generate" do
    let(:data) do
      {
        :header => [ {:type => "HEAD", :file_id => "1" }],
        :body => [
          {:first => "Paul", :last => "Hewson" },
          {:first => "Dave", :last => "Evans" }
        ],
        :footer => [ {:type => "FOOT", :file_id => "1" }]
      }
    end

    it "generate a string" do
      expected = "HEAD         1\n      Paul    Hewson\n      Dave     Evans\nFOOT         1"

      expect(subject.generate(data)).to eq(expected)
    end

    context "when a required section is not present" do
      it "raise an error" do
        data.delete(:header)

        expect do
          subject.generate(data)
        end.to raise_error(Slither::RequiredSectionEmptyError)
      end
    end

    context "when a required section has no content" do
      it "raise an error" do
        data[:header] = []

        expect do
          subject.generate(data)
        end.to raise_error(Slither::RequiredSectionEmptyError)
      end
    end
  end
end
