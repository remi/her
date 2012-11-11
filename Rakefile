require "bundler"
require "rake"
require "yard"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :default => :spec

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = "spec/**/*_spec.rb"
end

desc "Generate YARD Documentation"
YARD::Rake::YardocTask.new do |task|
  task.options = [
    "-o", File.expand_path("../doc", __FILE__),
    "--readme=README.md",
    "--markup=markdown",
    "--markup-provider=redcarpet",
    "--no-private",
    "--no-cache",
    "--protected",
    "--title=Her",
  ]
  task.files   = ["lib/**/*.rb"]
end
