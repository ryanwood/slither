require 'slither/definition'
require 'slither/section'
require 'slither/column'
require 'slither/parser'
require 'slither/generator'

module Slither

  class DuplicateColumnNameError < StandardError; end
  class RequiredSectionNotFoundError < StandardError; end
  class RequiredSectionEmptyError < StandardError; end
  class FormattedStringExceedsLengthError < StandardError; end
  class ColumnMismatchError < StandardError; end


  def self.define(name, options = {}, &block)
    definition = Definition.new(options)
    yield(definition)
    definitions[name] = definition
    definition
  end

  def self.generate(definition_name, data)
    definition = definition(definition_name)
    raise ArgumentError, "Definition name '#{name}' was not found." unless definition
    generator = Generator.new(definition)
    generator.generate(data)
  end

  def self.write(filename, definition_name, data)
    File.open(filename, 'w') do |f|
      f.write generate(definition_name, data)
    end
  end

  def self.parse(filename, definition_name)
    raise ArgumentError, "File #{filename} does not exist." unless File.exists?(filename)
    definition = definition(definition_name)
    raise ArgumentError, "Definition name '#{definition_name}' was not found." unless definition
    parser = Parser.new(definition, filename)
    parser.parse
  end

  private

  def self.definitions
    @@definitions ||= {}
  end

  def self.definition(name)
    definitions[name]
  end
end
