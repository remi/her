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
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "json", "~> 2.6.3"
  s.add_development_dependency "rake", "~> 13.0.6"
  s.add_development_dependency "rspec", "~> 3.12"

  s.add_runtime_dependency "activemodel", ">= 7.0.4.3"
  s.add_runtime_dependency "faraday", "~> 2.7.4"

  s.add_runtime_dependency "multi_json", "~> 1.15.0"
end
