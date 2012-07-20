# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "her/version"

Gem::Specification.new do |s|
  s.name        = "her"
  s.version     = Her::VERSION
  s.authors     = ["Rémi Prévost"]
  s.email       = ["remi@exomel.com"]
  s.homepage    = "http://remiprev.github.com/her"
  s.license     = "MIT"
  s.summary     = "A simple Representational State Transfer-based Hypertext Transfer Protocol-powered Object Relational Mapper. Her?"
  s.description = "Her is an ORM that maps REST resources and collections to Ruby objects"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake", "~> 0.9.2"
  s.add_development_dependency "rspec", "~> 2.11"
  s.add_development_dependency "yard", "~> 0.8"
  s.add_development_dependency "redcarpet", "~> 2.1"
  s.add_development_dependency "mocha", "~> 0.12"
  s.add_development_dependency "guard", "~> 1.2"
  s.add_development_dependency "guard-rspec", "~> 0.7"
  s.add_development_dependency "rb-fsevent", "~> 0.9"
  s.add_development_dependency "growl", "~> 1.0"

  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "faraday", "~> 0.8"
  s.add_runtime_dependency "multi_json", "~> 1.3"
end
