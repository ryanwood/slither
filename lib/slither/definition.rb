# frozen_string_literal: true

module Slither
  class Definition
    attr_reader :sections, :templates, :options

    def initialize(options = {})
      @sections = []
      @templates = {}
      @options = { align: :right, by_bytes: true }.merge(options)
    end

    def section(name, options = {}, &block)
      if section_using_reserved_name?(name) || section_already_defined?(name)
        raise(ArgumentError, "Reserved or duplicate section name: '#{name}'")
      end

      section = Slither::Section.new(name, @options.merge(options))
      section.definition = self

      yield(section) if block

      sections << section
      section
    end

    def template(name, options = {}, &block)
      section = Slither::Section.new(name, @options.merge(options))
      yield(section) if block
      @templates[name] = section
    end

    # rubocop:disable Style/MissingRespondToMissing
    def method_missing(method, *args, &block)
      section(method, *args, &block)
    end
    # rubocop:enable Style/MissingRespondToMissing

    private

    def section_using_reserved_name?(name)
      Section::RESERVED_NAMES.include?(name)
    end

    def section_already_defined?(name)
      return false if sections.empty?

      section_names = sections.map(&:name)
      section_names.include?(name)
    end
  end
end
