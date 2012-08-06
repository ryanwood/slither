class Slither
  class Parser
        
    def initialize(definition, file)
      @definition = definition
      @repeat_counter = 1
      @repeat_section_name = nil
      @file = file
      # This may be used in the future for non-linear or repeating sections
      @mode = :linear
    end
    
    def parse()
      @parsed = {}
      @content = read_file      
      unless @content.empty?
        @definition.non_repeatable_sections.each do |section|
          rows = fill_content(section)
          
          #if no matches were found this might be a repeatable section
          if rows == 0
            repeatable_rows = parse_repeatable_sections
            while repeatable_rows > 0
              repeatable_rows = parse_repeatable_sections
            end
            rows = fill_content(section)
          end
          
          if rows == 0 and !section.optional
            raise(Slither::RequiredSectionNotFoundError, "Required section '#{section.name}' was not found.") 
          end
          
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
      
      def fill_content(section, repeatable=false)
        matches = 0
        loop do
          line = @content.first
          break unless section.match(line) 
          if repeatable
            unless @repeat_section == section.name
              @repeat_section_name = "#{section.name}#{@definition.repeater}#{@repeat_counter}"
              @repeat_counter += 1
            end
          end
          add_to_section(section, line, repeatable)
          matches += 1
          @content.shift
        end
        matches
      end
      
      def parse_repeatable_sections
        matches = 0
        @definition.repeatable_sections.each do |section|
          matches = fill_content(section, true)
        end
        matches
      end
      
      def add_to_section(section, line, repeatable)
        key = repeatable ? @repeat_section_name : section.name
        @parsed[key] = [] unless @parsed[key]
        @parsed[key] << section.parse(line)
      end
    
  end
end