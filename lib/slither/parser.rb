class Slither
  class Parser
        
    def initialize(definition, file_io)
      @definition = definition
      @file = file_io
      # This may be used in the future for non-linear or repeating sections
      @mode = :linear
    end
    
    def parse()
      @parsed = {}

      @file.each_line do |line|
        @definition.sections.each do |section|
          rows = fill_content(line, section)
          raise(Slither::RequiredSectionNotFoundError, "Required section '#{section.name}' was not found.") unless rows > 0 || section.optional
        end
      end

      @parsed
    end
    
    private
    

      def fill_content(line, section)
        matches = 0
        loop do
          break unless section.match(line)

          @parsed[section.name] = [] unless @parsed[section.name]
          @parsed[section.name] << section.parse(line)
          matches += 1
        end
        matches
      end
      
  end
end