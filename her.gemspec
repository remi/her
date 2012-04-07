# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "her/version"

Gem::Specification.new do |s|
  s.name        = "her"
  s.version     = Her::VERSION
  s.authors     = ["Rémi Prévost"]
  s.email       = ["remi@exomel.com"]
  s.homepage    = "https://github.com/remiprev/her"
  s.summary     = "A REST-based HTTP-powered ORM"
  s.description = "Her is an ORM that maps REST resources to ActiveModel-like Ruby objects"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "rest-client"
end
