require 'date'

class Slither
  class ParserError < RuntimeError; end
  
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

    def is_variable_length?
      # For variable length fields, we set length to a symbol for another column name, rather than
      # an integer.
      !length.is_a?(Integer)
    end
    
    def unpacker
      # Default types would just be defined by A#{length}
      # Variable types would be defined by |#{column_name|
      # We will turn those into variable unpackers in section.parse
      if is_variable_length?
        "[#{@length}]"
      else
        "A#{@length}"
      end
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
      when :julian_date
        begin
          Date.jd(value)
        rescue
          value
        end
      else
        value.strip
      end
    rescue
      raise ParserError, "The value '#{value}' could not be converted to type #{@type}: #{$!}"
    end
    
    def format(value)
      if is_variable_length?
        pad(formatter(value) % _to_s(value))
      else
        pad(formatter % _to_s(value))
      end
    rescue
      puts "Could not format column '#{@name}' as a '#{@type}' with formatter '#{formatter(value)}' and value of '#{value}' (formatted: '#{_to_s(value)}'). #{$!}"
    end
       
    private
    
      def formatter(value=nil)
        "%#{aligner}#{sizer(value)}s"
      end
          
      def aligner
        @alignment == :left ? '-' : ''
      end
      
      def sizer(value=nil)
        if is_variable_length? && value
          value.size
        else
          (@type == :float && @precision) ? @precision : @length
        end
      end
      
      # Manually apply padding. sprintf only allows padding on numeric fields.
      def pad(value)
      	return value unless @padding == :zero
      	matcher = @alignment == :right ? /^ +/ : / +$/
      	space = value.match(matcher)
      	return value unless space
      	value.gsub(space[0], '0' * space[0].size)
      end
      
      def _to_s(value)
        result = case @type
        when :date            
          # If it's a DBI::Timestamp object, see if we can convert it to a Time object
          unless value.respond_to?(:strftime)
            value = value.to_time if value.respond_to?(:to_time)
          end
          if value.respond_to?(:strftime)        
            if @options[:format]
              value.strftime(@options[:format])
            else
              value.strftime
            end
          else
            value.to_s
          end
        when :float
          @options[:format] ? @options[:format] % value.to_f : value.to_f.to_s
        when :money
          "%.2f" % value.to_f
        when :money_with_implied_decimal
          "%d" % (value.to_f * 100)
        else 
          value.to_s
        end
        if is_variable_length?
          result
        else
          validate_size result
        end
      end

      def assert_valid_options(options)
        unless options[:align].nil? || [:left, :right].include?(options[:align])
          raise ArgumentError, "Option :align only accepts :right (default) or :left"
        end
        unless options[:padding].nil? || [:space, :zero].include?(options[:padding])
          raise ArgumentError, "Option :padding only accepts :space (default) or :zero"
        end
      end
      
      def validate_size(result)
        # Handle when length is out of range
        if result.length > @length
          if @truncate
            start = @alignment == :left ? 0 : -@length
            result = result[start, @length]
          else
            raise Slither::FormattedStringExceedsLengthError, 
              "The formatted value '#{result}' in column '#{@name}' exceeds the allowed length of #{@length} chararacters."
          end
        end
        result
      end
  end  
end
