require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "sequel_plus"
    gem.summary = "provides plugins and extensions for Sequel (forked from mwlang)"
    gem.description = "Provides plugins and extensions for Sequel (forked from mwlang)"
    gem.email = "maxs@webwizarddesign.com (forked from mwlang@cybrains.net)"
    gem.homepage = "http://github.com/perldork/sequel_plus"
    gem.authors = ["Michael Lang", "3.4.2 patches by Max Schubert"]
    gem.files = [
       "LICENSE",
       "README.md",
       "Rakefile",
       "lib/*",
       "lib/**/*",
       "test/*"
    ]
    
    gem.add_development_dependency "bacon", ">= 1.0.0"
    gem.add_dependency "sequel", ">= 3.0.0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "sequel_plus #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
