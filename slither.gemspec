# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "slither/version"

Gem::Specification.new do |s|
  s.name        = "slither"
  s.version     = Slither::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ryan Wood"]
  s.email       = ["ryan@ryanwood.com"]
  s.homepage    = "http://github.com/ryanwood/slither"
  s.summary     = %q{A simple, clean DSL for describing, writing, and parsing fixed-width text files.}
  s.description = %q{A simple, clean DSL for describing, writing, and parsing fixed-width text files.}

  s.rubyforge_project = "slither"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
