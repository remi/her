# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "her/version"

Gem::Specification.new do |s|
  s.name        = "her"
  s.version     = Her::VERSION
  s.authors     = ["Rémi Prévost"]
  s.email       = ["remi@exomel.com"]
  s.homepage    = "https://github.com/remi/her"
  s.license     = "MIT"
  s.summary     = "A simple Representational State Transfer-based Hypertext Transfer Protocol-powered Object Relational Mapper. Her?"
  s.description = "Her is an ORM that maps REST resources and collections to Ruby objects"
  
  s.metadata["bug_tracker_uri"]   = "https://github.com/remi/her/issues"
  s.metadata["changelog_uri"]     = "https://github.com/remi/her/blob/master/UPGRADE.md"
  s.metadata["documentation_uri"] = "https://github.com/remi/her"
  s.metadata["source_code_uri"]   = "https://github.com/remi/her"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "json", "~> 1.8"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.5"

  s.add_runtime_dependency "activemodel", ">= 4.2.1"
  s.add_runtime_dependency "faraday", ">= 0.8"
  s.add_runtime_dependency "multi_json", "~> 1.7"
end
