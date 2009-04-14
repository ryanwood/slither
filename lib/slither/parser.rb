class Slither
  class Parser
    
    def initialize(definition, file)
      @definition = definition
      @file = file
    end
    
    def parse
      parsed = {}
      sections = @definition.sections.dup
      current_section = sections.shift
      limit = nil
      count = 1
      File.open(@file, 'r') do |f|        
        while (line = f.gets) do
          logger.debug "*** Starting line #{count}: '#{line.chomp}'"
          match_section = nil
          logger.debug " -- starting matching"
          until(match_section || current_section.nil?)
            logger.debug "Current Section: #{current_section.name.to_s.upcase}"
            match_section = match(line, current_section)
            current_section = sections.shift unless match_section
          end
          if current_section
            parsed[current_section.name] = [] unless parsed[current_section.name]
            parsed[current_section.name] << current_section.parse(line)
          end
          count += 1
        end
      end
      parsed
    end
    
    private
    
      def match(line, section)
        # parsed = current_section.parse_line(line)
        if section.match(line)
          puts "Line matches section #{section.name.to_s.upcase}."
          return section
        else
          puts "Line DOES NOT MATCH section #{section.name.to_s.upcase}."
          return nil
        end
      end
    
  end
end