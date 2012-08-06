class Slither
  class Generator
		
		def initialize(definition)
			@definition = definition
		end
		
		def generate(data)
	    @builder = []
	    data.each do |section_name,content|
	      #remove #{@definition.repeater}[number] which was created by repeating rows
	      repeat_regex = Regexp.new("#{@definition.repeater}{1}\\d+\\z")
        section_name = section_name.to_s.gsub(repeat_regex, '')
	      
	      section = @definition.find_section(section_name.to_sym)
	      raise(Slither::UndefinedSectionError, "Undefined section '#{section_name}'.") if section.nil?
	      
  	    content = [content] unless content.is_a?(Array)
  	    raise(Slither::UknownSectionError, "Required section '#{section.name}' was empty.") if content.empty?
  	    content.each do |row|
  	      @builder << section.format(row)
  	    end
	    end
	    @builder.join("\n")
		end
		
	end
end