require 'date'

class Slither
  class Column
    attr_reader :name, :length, :alignment, :options
    
    def initialize(name, length, options = {})
      assert_valid_options(options)
      @name = name
      @length = length
      @options = options
      @alignment = options[:align] || :right
      @type = options[:type] || :string
    end
    
    def formatter
      "%#{aligner}#{length}s"
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
    
    private
    
    def aligner
      @alignment == :left ? '-' : ''
    end
    
    def assert_valid_options(options)
      unless options[:align].nil? || [:left, :right].include?(options[:align])
        raise ArgumentError, "Option :align only accepts :right (default) or :left."
      end
    end    
  end  
end