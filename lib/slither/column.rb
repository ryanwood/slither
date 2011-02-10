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
    rescue
      raise ParserError, "The value '#{value}' could not be converted to type #{@type}: #{$!}"
    end
    
    def format(value)
      if @type == :money || @type == :money_with_implied_decimal
        format_money(value)
      else
        pad(formatter % to_s(value))
      end
    rescue
      puts "Could not format column '#{@name}' as a '#{@type}' with formatter '#{formatter}' and value of '#{value}' (formatted: '#{to_s(value)}'). #{$!}"
    end
       
    private
    
      def format_money(value)
         ali = @alignment == :right ? '' : ( @padding == :zero ? '0' : '-' )
         format = @type == :money_with_implied_decimal ? "%#{ali}#{sizer}d" : "%#{ali}#{sizer}.2f"
         value = 100 * value.to_f if @type == :money_with_implied_decimal       
         result = format % value
         validate_size result
      end    

      def formatter
        "%#{aligner}#{sizer}s"
      end
          
      def aligner
        @alignment == :left ? '-' : ''
      end
      
      def sizer
        (@type == :float && @precision) ? @precision : @length
      end
      
      # Manually apply padding. sprintf only allows padding on numeric fields.
      def pad(value)
      	return value unless @padding == :zero
      	matcher = @alignment == :right ? /^ +/ : / +$/
      	space = value.match(matcher)
      	return value unless space
      	value.gsub(space[0], '0' * space[0].size)
      end
      
      def to_s(value)
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
        validate_size result
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