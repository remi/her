source "https://rubygems.org"
gemspec

if RbConfig::CONFIG['RUBY_PROGRAM_VERSION'] && RbConfig::CONFIG['RUBY_PROGRAM_VERSION'] >= '1.9.3'
  gem 'activemodel', '>= 3.2.0', "< 4.1"
  gem 'activesupport', '>= 3.2.0', "< 4.1"
else
  gem 'activemodel', '~> 3.2.0'
  gem 'activesupport', '~> 3.2.0'
end
