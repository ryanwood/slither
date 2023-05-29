# frozen_string_literal: true

require_relative "slither/column"
require_relative "slither/definition"
require_relative "slither/generator"
require_relative "slither/parser"
require_relative "slither/section"
require_relative "slither/version"

module Slither
  class Error < StandardError; end

  class DuplicateColumnNameError < StandardError; end
  class RequiredSectionNotFoundError < StandardError; end
  class RequiredSectionEmptyError < StandardError; end
  class FormattedStringExceedsLengthError < StandardError; end
  class ColumnMismatchError < StandardError; end
  class LineWrongSizeError < StandardError; end
  class SectionsNotSameLengthError < StandardError; end

  def self.define(name, options = {}, &block)
    definition = Definition.new(options)

    yield(definition) if block

    definitions[name] = definition
    definition
  end

  # Generate a File from Data.
  def self.generate(definition_name, data)
    definition = definition(definition_name)

    raise ArgumentError, "Definition name '#{name}' was not found." unless definition

    generator = Generator.new(definition)
    generator.generate(data)
  end

  # Writes the File
  def self.write(filename, definition_name, data)
    File.open(filename, "w") do |f| # rubocop:disable Style/FileWrite
      f.write generate(definition_name, data)
    end
  end

  def self.parse(filename, definition_name)
    raise ArgumentError, "File #{filename} does not exist." unless File.exist?(filename)

    file_io = File.open(filename, "r")
    parseIo(file_io, definition_name)
  end

  def self.parseIo(io, definition_name) # rubocop:disable Naming/MethodName
    definition = definition(definition_name)

    raise ArgumentError, "Definition name '#{definition_name}' was not found." unless definition

    parser = Parser.new(definition, io)
    definition.options[:by_bytes] ? parser.parse_by_bytes : parser.parse
  end

  private

  def self.definitions
    @@definitions ||= {} # rubocop:disable Style/ClassVars
  end

  def self.definition(name)
    definitions[name]
  end

  private_class_method :definitions, :definition
end
