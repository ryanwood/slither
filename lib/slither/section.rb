class Slither
  class Section
    attr_reader :name, :columns, :options
    
    def initialize(name, options = {})
      @name = name
      @options = options
      @columns = []
      @trap = options[:trap]
    end
    
    def column(name, length, options = {})
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
    
    def format(data)
      row = ''
      # logger.debug data
      @columns.each do |column|
        # logger.debug "Formatting column '#{column.name}'"
        # logger.debug "Column options: #{column.options.inspect}"
        row += (column.formatter % data[column.name])
      end
      row
    end
    
    def merge!(section)
      # Append template columns
      @columns = @columns + section.columns
      # Section options should trump template options
      @options = section.options.merge(@options)
    end
    
    def parse(line)
      puts "Unpacker: #{unpacker}"
      line_data = line.unpack(unpacker)
      row = {}
      @columns.each_with_index do |c, i|
        row[c.name] = c.to_type(line_data[i]) unless c.name == :spacer
      end
      row
    end
    
    def match(raw_line)
      return true unless @trap
      @trap.call(raw_line)
    end
  
    private
      
      def aligner
        (@options[:align] && @options[:align] == :left) ? '-' : ''
      end
      
      def unpacker
        @columns.map { |c| c.unpacker }.join('')
      end
      
      def unpack(line, pattern, columns)
        row = line.unpack(pattern)
        line = {}
        mappings.each_with_index do |key, i|
          line[key.to_sym] = row[i].strip
        end
        line
      end
  end  
end