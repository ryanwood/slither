# encoding: utf-8

Gem::Specification.new do |s|
  s.name = %q{slither}
  s.version = "0.99.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ryan Wood"]
  s.date = %q{2010-10-07}
  s.description = %q{A simple, clean DSL for describing, writing, and parsing fixed-width text files.}
  s.email = %q{ryan.wood@gmail.com}
  s.extra_rdoc_files = ["History.txt", "README.rdoc"]
  s.files = ["History.txt", "README.rdoc", "Rakefile", "TODO", "lib/slither.rb", "lib/slither/column.rb", "lib/slither/definition.rb", "lib/slither/generator.rb", "lib/slither/parser.rb", "lib/slither/section.rb", "lib/slither/slither.rb", "slither.gemspec", "spec/column_spec.rb", "spec/definition_spec.rb", "spec/generator_spec.rb", "spec/parser_spec.rb", "spec/section_spec.rb", "spec/slither_spec.rb", "spec/spec_helper.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/ryanwood/slither}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.summary = %q{A simple, clean DSL for describing, writing, and parsing fixed-width text files}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bones>, [">= 2.5.1"])
    else
      s.add_dependency(%q<bones>, [">= 2.5.1"])
    end
  else
    s.add_dependency(%q<bones>, [">= 2.5.1"])
  end
end

