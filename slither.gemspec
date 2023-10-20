# frozen_string_literal: true

require_relative "lib/slither/version"

Gem::Specification.new do |spec|
  spec.name = "slither"
  spec.version = Slither::VERSION
  spec.authors = ["Ryan Wood"]
  spec.summary = "A simple, clean DSL for describing, writing, and parsing fixed-width text files."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.homepage = "https://github.com/ryanwood/slither"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["rubygems_mfa_required"] = "true"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
