class Slither
	class Generator
		
		def initialize(definition)
			@definition = definition
		end
		
		def generate(data)
	    builder = []
	    @definition.sections.each do |section|
	      section_data = data[section.name]
	      section_data = [section_data] unless section_data.is_a?(Array)
	      section_data.each do |row|
	        builder << section.format(row)
	      end
	    end
	    builder.join("\n")
		end
		
	end
end