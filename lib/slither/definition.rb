# frozen_string_literal: true

module Slither
  # A Definition is the parent object that contains the information about how a fixed-width file is
  # formatted. It contains a collection of sections, each of which contains a collection of fields.
  class Definition
    attr_reader :sections, :templates, :options

    # Initializes a new Definition object.
    #
    # @param options [Hash] An optional hash of configuration options.
    # @option options [Symbol] :align ( :right ) The alignment for fields, can be :left, :right, or :center.
    # @option options [Boolean] :by_bytes ( true ) Whether to align fields by bytes or characters.
    #
    def initialize(options = {})
      @sections = []
      @templates = {}
      @options = { align: :right, by_bytes: true }.merge(options)
    end

    # Defines a new Section within the Definition.
    #
    # @param name [String] The name of the section.
    # @param options [Hash] An optional hash of section-specific configuration options.
    # @yield [Section] A block for defining fields within the section.
    # @yieldparam section [Section] The section object to be configured.
    # @return [Section] The newly created section.
    #
    # @raise [ArgumentError] if the section name is reserved or already defined.
    #
    # @example Define a section for the "header" part of the fixed-width file.
    #   definition.section(:header, align: :left) do |section|
    #     # The trap tells Slither which lines should fall into this section
    #     section.trap { |line| line[0,4] == 'HEAD' }
    #     # Use the boundary template for the columns
    #     section.template(:boundary)
    #   end
    #
    def section(name, options = {}, &block)
      if section_using_reserved_name?(name) || section_already_defined?(name)
        raise ArgumentError, "Reserved or duplicate section name: '#{name}'"
      end

      section = Slither::Section.new(name, @options.merge(options))
      section.definition = self

      yield(section) if block

      sections << section
      section
    end

    # Defines a template, which can be reused to create multiple sections with the same configuration.
    #
    # @param name [String] The name of the template.
    # @param options [Hash] An optional hash of template-specific configuration options.
    # @yield [section] A block for configuring the template.
    # @yieldparam section [Section] The template object to be configured.
    #
    # @example Define a template for the "boundary" part of the fixed-width file.
    #   definition.template(:boundary) do |section|
    #     section.column(:record_type, 4)
    #     section.column(::company_id, 12)
    #
    def template(name, options = {}, &block)
      section = Slither::Section.new(name, @options.merge(options))
      yield(section) if block
      @templates[name] = section
    end

    # Provides a way to define sections using method calls. For example,
    #  you can call `my_section` instead of `section('my_section')`.
    #
    # @param method [Symbol] The name of the section.
    # @param args [Array] Additional arguments.
    # @param block [Block] A block for defining fields within the section.
    # @return [Section] The newly created section.
    #
    def method_missing(method, *args, &block) # rubocop:disable Style/MissingRespondToMissing
      section(method, *args, &block)
    end

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
