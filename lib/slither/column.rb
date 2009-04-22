require 'date'

class Slither
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
      # Only used with floats, this determines the decimal places
      @precision = options[:precision] 
    end
    
    def unpacker
      "A#{@length}"
    end
       
    def to_type(value)
      case @type
        when :integer: value.to_i
        when :float: value.to_f
        when :date:
          if @options[:date_format]
            Date.strptime(value, @options[:date_format])
          else
            Date.strptime(value)
          end
        else value.strip
      end
    end
    
    def format(value)
      pad(formatter % format_as_string(value))
    end
       
    private
    
      def formatter
        "%#{aligner}#{sizer}#{typer}"
      end
          
      def aligner
        @alignment == :left ? '-' : ''
      end
      
      def sizer
        (@type == :float && @precision) ? @precision : @length
      end
      
      def typer
        case @type
          when :integer: 'd'
          when :float: 's'
          else 's'
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
      
      def format_as_string(value)
        result = case @type
          when :date:
            if @options[:date_format]
              value.strftime(@options[:date_format])
            else
              value.strftime
            end
          else value.to_s
        end
        raise( 
          Slither::FormattedStringExceedsLengthError, 
          "The formatted value '#{result}' exceeds #{@length} chararacters, the allowable length of the '#{@name}' column."
        ) if result.length > @length
        result
      end

      def assert_valid_options(options)
        unless options[:align].nil? || [:left, :right].include?(options[:align])
          raise ArgumentError, "Option :align only accepts :right (default) or :left"
        end
        unless options[:padding].nil? || [:space, :zero].include?(options[:padding])
          raise ArgumentError, "Option :padding only accepts :space (default) or :zero"
        end
      end    
  end  
end