require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name        = "audrey2"
    gem.summary     = "Feed processing and aggregation"
    gem.description = "Audrey 2.0 is a command-line utility for customizable feed processing, aggregation, and output."
    gem.email       = "sven.aas@gmail.com"
    gem.homepage    = "http://github.com/svenaas/audrey2"
    gem.authors     = ["Sven Aas"]
    gem.add_dependency "feed-normalizer", "~>1.5.2"
    gem.add_dependency "haml", "~>3.0.13"
    gem.add_development_dependency "shoulda", ">= 2.11.1"
    gem.add_development_dependency "mocha", ">= 0.9.8"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
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

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "audrey2 #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
