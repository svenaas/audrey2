# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{audrey2}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sven Aas"]
  s.date = %q{2010-07-20}
  s.default_executable = %q{feedme}
  s.description = %q{Gem for feed processing and aggregation}
  s.email = %q{sven.aas@gmail.com}
  s.executables = ["feedme"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/audrey2.rb"
  ]
  s.homepage = %q{http://github.com/svenaas/audrey2}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Gem for feed processing and aggregation}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<feed-normalizer>, ["~> 1.5.2"])
      s.add_runtime_dependency(%q<haml>, ["~> 3.0.13"])
    else
      s.add_dependency(%q<feed-normalizer>, ["~> 1.5.2"])
      s.add_dependency(%q<haml>, ["~> 3.0.13"])
    end
  else
    s.add_dependency(%q<feed-normalizer>, ["~> 1.5.2"])
    s.add_dependency(%q<haml>, ["~> 3.0.13"])
  end
end
