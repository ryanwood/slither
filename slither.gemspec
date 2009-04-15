require 'rake'
spec = Gem::Specification.new do |s| 
  s.name = "slither"
  s.version = "0.99.0"
  s.author = "Ryan Wood"
  s.email = "ryan.wood@gmail.com"
  s.homepage = "http://ryanwood.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A simple clean DSL for writing and parsing fixed width text file."
  s.files = FileList["lib/**/*", 'TODO'].to_a
  s.require_path = "lib"
  # s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = false
  # s.extra_rdoc_files = ["README"]
  # s.add_dependency("dependency", ">= 0.x.x")
end