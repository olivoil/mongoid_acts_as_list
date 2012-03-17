# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid/acts_as_list/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_acts_as_list"
  s.version     = Mongoid::ActsAsList::VERSION
  s.authors     = ["Olivier Melcher"]
  s.email       = ["olivier.melcher@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Implementation of the acts as list gem for Mongoid}
  s.description = %q{}

  s.rubyforge_project = "acts_as_list"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  # s.add_development_dependency "factory_girl"
  s.add_development_dependency "database_cleaner"
  s.add_runtime_dependency "mongoid", [">= 2.0.1"]
end
