class Slither
  
  class RequiredSectionNotFoundError < StandardError; end
  
  class Parser
        
    def initialize(definition, file)
      @definition = definition
      @file = file
      # This may be used in the future for non-linear or repeating sections
      @mode = :linear
    end
    
    def parse()
      @parsed = {}
      @content = read_file      
      unless @content.empty?
        @definition.sections.each do |section|
          rows = fill_content(section)
          raise Slither::RequiredSectionNotFoundError unless rows > 0 || section.optional
        end
      end
      @parsed
    end
    
    private
    
      def read_file
        content = []
        File.open(@file, 'r') do |f|
          while (line = f.gets) do
            content << line
          end
        end
        content
      end
      
      def fill_content(section)
        matches = 0
        loop do
          line = @content.first
          break unless section.match(line) 
          add_to_section(section, line)
          matches += 1
          @content.shift
        end
        matches
      end
      
      def add_to_section(section, line)
        @parsed[section.name] = [] unless @parsed[section.name]
        @parsed[section.name] << section.parse(line)
      end
    
  end
end