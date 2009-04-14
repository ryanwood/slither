# $: << File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.dirname(__FILE__)
require 'rubygems'
require 'logging'
require 'yaml'
require 'slither/slither'
require 'slither/definition'
require 'slither/section'
require 'slither/column'
require 'slither/parser'
require 'slither/generator'

# Create default logger
DEFAULT_LOGGER = Logging::Logger['default']
  
simple_layout = Logging::Layouts::Pattern.new(:pattern => "%-5l %m\n")
dated_layout = Logging::Layouts::Pattern.new(
  :pattern => "%d %-5l %m\n",
  :date_pattern => "%Y-%m-%d %H:%M:%S",
  :date_method => 'to_s'    # overrides the :date_pattern
)
Logging::Appender.stdout.layout = simple_layout
DEFAULT_LOGGER.add_appenders(
  Logging::Appender.stdout #,
  # Logging::Appenders::File.new(File.join(LOG_DIR, "#{APP_ENV}.log"), :layout => dated_layout),
  # Logging::Appenders::File.new(File.join(LOG_DIR, "error.log"), :layout => dated_layout, :level => :warn)
)

def logger
  DEFAULT_LOGGER
end
