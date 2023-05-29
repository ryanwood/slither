# frozen_string_literal: true

require "date"
require "English"

module Slither
  class ParserError < RuntimeError; end

  # rubocop:disable Metrics/ClassLength
  class Column
    attr_reader :name, :length, :alignment, :type, :padding, :precision, :options

    def initialize(name, length, options = {})
      assert_valid_options(options)
      @name = name
      @length = length
      @options = options
      @alignment = options[:align] || :right
      @type = options[:type] || :string
      @padding = options[:padding] || :space
      @truncate = options[:truncate] || false
      # Only used with floats, this determines the decimal places
      @precision = options[:precision]
    end

    def unpacker
      "A#{@length}"
    end

    def parse(value)
      case @type
      when :integer
        value.to_i
      when :float, :money
        value.to_f
      when :money_with_implied_decimal
        value.to_f / 100
      when :date
        if @options[:format]
          Date.strptime(value, @options[:format])
        else
          Date.strptime(value)
        end
      else value.strip
      end

    # rubocop:disable Style/RescueStandardError
    rescue
      raise ParserError,
            "Error parsing column ''#{name}'. The value '#{value}' could not be converted to " \
            "type #{@type}: #{$ERROR_INFO}"
    end

    def format(value)
      string_formatted = formatter % to_s(value)

      pad(string_formatted)
    rescue
      puts "Could not format column '#{@name}' as a '#{@type}' with formatter '#{formatter}' " \
           "and value of '#{value}' (formatted: '#{to_s(value)}'). #{$ERROR_INFO}"
    end
    # rubocop:enable Style/RescueStandardError

    private

    # String formatter https://www.rubyguides.com/2012/01/ruby-string-formatting/
    # https://www.dotnetperls.com/format-ruby
    # Generates a string formatter using padding. Supports padding to the right or left as follow:
    # formatter (right side)
    # => "%10s"
    #   This will generate a formatter of 10 char string right aligned.
    #
    # formatter (left side)
    # => "%-10s"
    #   This will generate a formatter of 10 char strign left aligned.
    def formatter
      @formatter ||= "%#{aligner}#{sizer}s"
    end

    # Pad aligment, related with string formatting, we use - for left or nothing for right.
    def aligner
      @alignment == :left ? "-" : ""
    end

    def sizer
      @type == :float && @precision ? @precision : @length
    end

    # Manually apply padding. sprintf only allows padding on numeric fields.
    def pad(value)
      return value unless @padding == :zero

      matcher = @alignment == :right ? /^ +/ : / +$/
      space = value.match(matcher)

      return value unless space

      value.gsub(space[0], "0" * space[0].size)
    end

    def inspect
      "#<#{self.class} #{instance_variables.map { |iv| "#{iv}=>#{instance_variable_get(iv)}" }.join(", ")}>"
    end

    def to_s(value)
      result = case @type
               when :date
                 # If it's a DBI::Timestamp object, see if we can convert it to a Time object
                 handle_date_value(value)
               when :float
                 @options[:format] ? @options[:format] % value.to_f : value.to_f.to_s
               when :money
                 # rubocop:disable Style::FormatString
                 "%.2f" % value.to_f
               when :money_with_implied_decimal
                 "%d" % (value.to_f * 100)
                 # rubocop:enable Style::FormatString
               else
                 value.to_s
               end

      validate_size(result)
    end

    def handle_date_value(value)
      if value.respond_to?(:strftime)
        if @options[:format]
          value.strftime(@options[:format])
        else
          value.strftime
        end
      elsif value.respond_to?(:to_time)
        value.to_time.to_s
      else
        value.to_s
      end
    end

    def assert_valid_options(options)
      unless options[:align].nil? || [:left, :right].include?(options[:align])
        raise ArgumentError, "Option :align only accepts :right (default) or :left"
      end

      return if options[:padding].nil? || [:space, :zero].include?(options[:padding])

      raise ArgumentError, "Option :padding only accepts :space (default) or :zero"
    end

    def validate_size(result)
      # Handle when length is out of range
      if result.length > @length
        if @truncate
          start = @alignment == :left ? 0 : -@length
          result = result[start, @length]
        else
          raise Slither::FormattedStringExceedsLengthError,
                "The formatted value '#{result}' in column '#{@name}' exceeds the allowed length " \
                "of #{@length} chararacters."
        end
      end
      result
    end
  end
  # rubocop:enable Metrics/ClassLength
end
