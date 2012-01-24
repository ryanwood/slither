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
      @columns.each do |column|
        row += column.format(data[column.name])
      end
      row
    end
    
    def parse(line)
      line_data = line.unpack(unpacker)
      row = {}
      @columns.each_with_index do |c, i|
        row[c.name] = c.parse(line_data[i]) unless RESERVED_NAMES.include?(c.name)
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
      
      def unpacker
        @columns.map { |c| c.unpacker }.join('')
      end

  end  
end
