class Slither
  class Parser
        
    def initialize(definition, file_io)
      @definition = definition
      @file = file_io
      # This may be used in the future for non-linear or repeating sections
      @mode = :linear
    end
    
    def parse()
      parsed = {}

      @file.each_line do |line|
        line.chomp! if line
        @definition.sections.each do |section|
          if section.match(line)
            validate_length(line, section)
            parsed = fill_content(line, section, parsed)
          end
        end
      end

      @definition.sections.each do |section|
        raise(Slither::RequiredSectionNotFoundError, "Required section '#{section.name}' was not found.") unless parsed[section.name] || section.optional
      end
      parsed
    end
    
    def parse_by_bytes
      parsed = {}
      
      byte_length = @definition.sections.map{|sec| sec.length }.max  # all sections must be the same length for parse_by_bytes
      while record = @file.read(byte_length)
        record.force_encoding @file.external_encoding

        raise(Slither::LineWrongSizeError, "newline character was not at the end of byte group") unless newline?(record[-1])
        #record.chomp!
        @definition.sections.each do |section|
          if section.match(record)
            parsed = fill_content(record, section, parsed)
          end
        end
      end
      
      @definition.sections.each do |section|
        raise(Slither::RequiredSectionNotFoundError, "Required section '#{section.name}' was not found.") unless parsed[section.name] || section.optional
      end
      parsed
    end
    
    private
    
      def fill_content(line, section, parsed)
        parsed[section.name] = [] unless parsed[section.name]
        parsed[section.name] << section.parse(line)
        parsed
      end
      
      def validate_length(line, section)
        raise Slither::LineWrongSizeError, "Line wrong size: (#{line.length} when it should be #{section.length})" if line.length != section.length
      end
      
      def newline?(char)
        # \n or LF -> 10
        # \r or CR -> 13
        return false unless char && !char.empty?
        [10, 13].any?{|code| char.ord == code}
      end
      
  end
end