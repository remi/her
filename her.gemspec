# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "her/version"

Gem::Specification.new do |s|
  s.name        = "her"
  s.version     = Her::VERSION
  s.authors     = ["Rémi Prévost"]
  s.email       = ["remi@exomel.com"]
  s.homepage    = "http://her-rb.org"
  s.license     = "MIT"
  s.summary     = "A simple Representational State Transfer-based Hypertext Transfer Protocol-powered Object Relational Mapper. Her?"
  s.description = "Her is an ORM that maps REST resources and collections to Ruby objects"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 2.13"
  s.add_development_dependency "fivemat", "~> 1.2"
  s.add_development_dependency "json", "~> 1.7.7"

  s.add_runtime_dependency "activemodel", ">= 3.0.0"
  s.add_runtime_dependency "activesupport", ">= 3.0.0"
  s.add_runtime_dependency "faraday", "~> 0.8"
  s.add_runtime_dependency "multi_json", "~> 1.7"
end
