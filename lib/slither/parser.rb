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
        line.chomp!
        @definition.sections.each do |section|
          parsed = fill_content(line, section, parsed)
        end
      end

      @definition.sections.each do |section|
        raise(Slither::RequiredSectionNotFoundError, "Required section '#{section.name}' was not found.") unless parsed[section.name] || section.optional
      end
      parsed
    end
    
    private
    
      def fill_content(line, section, parsed)
        if section.match(line)
          validate_length(line, section)
          parsed[section.name] = [] unless parsed[section.name]
          parsed[section.name] << section.parse(line)
        end
        parsed
      end
      
      def validate_length(line, section)
        raise Slither::LineTooLongError, "Line too long (#{line.length} when it should be #{section.length})" if line.length > section.length
        raise Slither::LineTooShortError, "Line too short (#{line.length} when it should be #{section.length})" if line.length < section.length
      end
      
  end
end