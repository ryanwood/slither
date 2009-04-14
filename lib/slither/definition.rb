class Slither  
  class Definition
    attr_reader :sections, :options
    
    def initialize(options = {})
      @sections = []
      @templates = {}
      @options = { :align => :right }.merge(options)
    end
    
    def section(name, options = {})
      raise( ArgumentError, "You must pass a block or the :template option") unless block_given? || options[:template]
      # logger.debug @sections
      raise( ArgumentError, "Duplicate section name: '#{name}'") if @sections.size > 0 && @sections.map{ |s| s.name }.include?( name )
      
      section = Slither::Section.new(name, @options.merge(options))
      section.merge! @templates[options[:template]]  if options[:template]
      
      yield(section) if block_given?
      @sections << section
      section
    end
    
    def template(name, options = {})
      section = Slither::Section.new(name, @options.merge(options))
      yield(section)
      @templates[name] = section
    end    
  end  
end