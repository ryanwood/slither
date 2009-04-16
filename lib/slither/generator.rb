class Slither
  
  class RequiredSectionEmptyError < StandardError; end
	
  class Generator
		
		def initialize(definition)
			@definition = definition
		end
		
		def generate(data)
	    @builder = []
	    @definition.sections.each do |section|
	      content = data[section.name]
	      if content
  	      content = [content] unless content.is_a?(Array)
  	      raise Slither::RequiredSectionEmptyError if content.empty?
  	      content.each do |row|
  	        @builder << section.format(row)
  	      end
  	    else
  	      raise Slither::RequiredSectionEmptyError unless section.optional
	      end
	    end
	    @builder.join("\n")
		end
		
	end
end