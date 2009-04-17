require 'rake'
require 'spec/rake/spectask'

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_files = FileList['spec/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

begin
  require 'bones'
  Bones.setup
rescue LoadError
  load 'tasks/setup.rb'
end

ensure_in_path 'lib'
require 'bones'

task :default => 'spec:run'

PROJ.name = 'slither'
PROJ.authors = 'Ryan Wood'
PROJ.email = 'ryan.wood@gmail.com'
PROJ.url = 'http://github.com/ryanwood/slither'
PROJ.version = '0.99.0'
PROJ.exclude = %w(\.git .gitignore ^tasks \.eprj ^pkg)
PROJ.readme_file = 'README.rdoc'

#PROJ.rubyforge.name = 'codeforpeople'

PROJ.rdoc.exclude << '^data'
PROJ.notes.exclude = %w(^README\.rdoc$ ^data ^pkg)

# PROJ.svn.path = 'bones'
# PROJ.spec.opts << '--color'