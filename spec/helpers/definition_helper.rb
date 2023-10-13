# frozen_string_literal: true

module DefinitionHelper
  # rubocop:disable Metrics/AbcSize
  def simple_definition
    Slither.define :simple, by_bytes: false do |d|
      # This is a template section that can be reused in other sections
      d.template :boundary do |t|
        t.column :record_type, 4
        t.column :company_id, 12
      end

      # Create a header section
      d.header align: :left do |header|
        # The trap tells Slither which lines should fall into this section
        header.trap { |line| line[0, 4] == "HEAD" }
        # Use the boundary template for the columns
        header.template :boundary
      end

      d.body do |body|
        body.trap { |line| line[0, 4] =~ /[^(HEAD|FOT)]/ }
        body.column :id, 10, type: :integer
        body.column :name, 10, align: :left
        body.spacer 3
        body.column :state, 2
      end

      d.footer do |footer|
        footer.trap { |line| line[0, 4] == "FOOT" }
        footer.template :boundary
        footer.column :record_count, 10
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def simple_definition_test_data
    {
      header: [
        { record_type: "HEAD", company_id: "ABC" }
      ],
      body: [
        { id: 12, name: "Ryan", state: "SC" },
        { id: 23, name: "Joe", state: "VA" },
        { id: 42, name: "Tommy", state: "FL" }
      ],
      footer: [
        { record_type: "FOOT", company_id: "ABC", record_count: "record" }
      ]
    }
  end

  def simple_definition_file
    "spec/fixtures/simple_file"
  end
end
