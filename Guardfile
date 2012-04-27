require "guard/guard"

guard "rspec", :cli => "--colour --format=documentation" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/.+\.rb$}) { "spec" }
  watch("spec/spec_helper.rb") { "spec" }
end
