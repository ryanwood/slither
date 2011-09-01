class Slither
  class Section
    attr_accessor :definition, :optional
    attr_reader :name, :columns, :options
    
    RESERVED_NAMES = [:spacer]
    
    def initialize(name, options = {})
      @name = name
      @options = options
      @columns = []
      @trap = options[:trap]
      @optional = options[:optional] || false
    end
    
    def column(name, length, options = {})
      raise(Slither::DuplicateColumnNameError, "You have already defined a column named '#{name}'.") if @columns.map do |c|
        RESERVED_NAMES.include?(c.name) ? nil : c.name
      end.flatten.include?(name)
      col = Column.new(name, length, @options.merge(options))
      @columns << col
      col
    end
    
    def spacer(length)
      column(:spacer, length)
    end
    
    def trap(&block)
      @trap = block
    end
    
    def template(name)
      template = @definition.templates[name]
      raise ArgumentError, "Template #{name} not found as a known template." unless template
      @columns = @columns + template.columns
      # Section options should trump template options
      @options = template.options.merge(@options)
    end
    
    def format(data)
      # raise( ColumnMismatchError,
      #   "The '#{@name}' section has #{@columns.size} column(s) defined, but there are #{data.size} column(s) provided in the data."
      # ) unless @columns.size == data.size
      row = ''      
      # First, find any variable length columns, count the characters in them, and input
      # their variable length field values into the data hash so that the formatter knows
      # how to output them
      @columns.select{|c| c.is_variable_length? }.each do |column|
        data[column.length.to_sym] = data[column.name].size
      end
      @columns.each do |column|
        if column.is_variable_length?
          row += column.format(data[column.name])
        else
          row += column.format(data[column.name])
        end
      end
      row
    end
    
    def parse(line)
      line_data = get_line_data(line, unpacker)
      parse_row(line_data)
    end

    def parse_row(array)
      row = {}
      @columns.each_with_index do |c, i|
        row[c.name] = c.parse(array[i].to_s) unless RESERVED_NAMES.include?(c.name)
      end
      row
    end
    
    def match(raw_line)
      raw_line.nil? ? false : @trap.call(raw_line)
    end
    
    def method_missing(method, *args)
      column(method, *args)
    end
  
    private

      def get_line_data(line, unpack_string)
        # Here we either just line.unpack(unpacker), if there are no strings, or we unpack to the first "variable length" field marker,
        # figure out what the next unpacker string should be, and recurse with that variable length field marker replaced.
        #
        # Example:
        #   Say we have the file:
        #   AAABBCCC001DFF
        #   
        #   We also have the unpacker string as follows:
        #   A3A2A3C3[foo]A2
        #
        #   Then we want to parse to the first [ char, grab the content in between the brackets, reference the column referenced by the string in it
        #   to determine the length of the unpacker replacement (in this case, A1 because 001 == 1, and that's the foo column (for instance)
        #
        #   So then we call get_line_data(A3A2A3A3A1A2)
        #
        #   And since there are no variable length field markers remaining, we fall through to the original implementation, which was:
        #
        # BEGIN IMPLEMENTATION
        # Find the first open bracket (to signify a variable length field)
        var_starts = (unpack_string =~ /\[/)
        # Find the matching close bracket
        var_ends = (unpack_string =~ /\]/)
        if var_starts
          raise "Invalid unpacker" unless var_ends # If no closing bracket, this is an exception
          unpack_string_beginning = unpack_string[0..var_starts-1]
          unpack_string_end = unpack_string[var_ends+1..-1]
          length_field_name = unpack_string[var_starts+1..var_ends-1] # Get the variable length field name
          partial_result = line.unpack(unpack_string_beginning)
          fields = parse_row(partial_result)
          length = (fields[length_field_name.to_sym]).to_i
          new_unpack_string = unpack_string_beginning + "A#{length}" + unpack_string_end
          return get_line_data(line, new_unpack_string)
        else
          return line.unpack(unpack_string)
        end
      end
      
      # The initial unpacker
      def unpacker
        @columns.map { |c| c.unpacker }.join('')
      end

  end  
end
