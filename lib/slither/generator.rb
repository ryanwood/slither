# frozen_string_literal: true

module Slither
  class Generator
    def initialize(definition)
      @definition = definition
    end

    def generate(data)
      @builder = []

      sections.each do |section|
        content = data[section.name]

        if content
          content = [content] unless content.is_a?(Array)

          raise_required_section_empty(section) if content.empty?

          content.each do |row|
            builder << section.format(row)
          end
        else
          raise_required_section_empty(section) unless section.optional
        end
      end

      builder.join("\n")
    end

    private

    attr_reader :definition, :builder

    def sections
      definition.sections
    end

    def raise_required_section_empty(section)
      raise(
        Slither::RequiredSectionEmptyError,
        "Required section '#{section.name}' was empty."
      )
    end
  end
end
