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
        next if line.empty?
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
      
      all_section_lengths = @definition.sections.map{|sec| sec.length }
      byte_length = all_section_lengths.max
      all_section_lengths.each { |bytes| raise(Slither::SectionsNotSameLengthError,
          "All sections must have the same number of bytes for parse by bytes") if bytes != byte_length }
      
      while record = @file.read(byte_length)
        
        unless remove_newlines! && byte_length == record.length
          parsed_line = parse_for_error_message(record)
          raise(Slither::LineWrongSizeError, "Line wrong size: No newline at #{byte_length} bytes. #{parsed_line}") 
        end
    
        record.force_encoding @file.external_encoding
        
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
        parsed[section.name] ||= []
        parsed[section.name] << section.parse(line)
        parsed
      end
      
      def validate_length(line, section)
        if line.length != section.length
          parsed_line = parse_for_error_message(line)
          raise Slither::LineWrongSizeError, "Line wrong size: (#{line.length} when it should be #{section.length}. #{parsed_line})" 
        end
      end
      
      def remove_newlines!
        return true if @file.eof?
        b = @file.getbyte
        if b == 10 || b == 13 && @file.getbyte == 10
          return true
        else
          @file.ungetbyte b
          return false
        end
      end
      
      def newline?(char_code)
        # \n or LF -> 10
        # \r or CR -> 13
        [10, 13].any?{|code| char_code == code}
      end
      
      def parse_for_error_message(line)
        parsed = ''
        line.force_encoding @file.external_encoding
        @definition.sections.each do |section|
          if section.match(line)
            parsed = section.parse_when_problem(line)
          end
        end
        parsed
      end
      
  end
end