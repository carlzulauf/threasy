# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'threasy/version'

Gem::Specification.new do |s|
  s.name          = "threasy"
  s.version       = Threasy::VERSION
  s.authors       = ["Carl Zulauf"]
  s.email         = ["carl@linkleaf.com"]
  s.summary       = %q{Simple threaded background jobs and scheduling.}
  s.description   = %q{Dead simple in-process background job solution using threads, with support for scheduled jobs.}
  s.homepage      = "http://github.com/carlzulauf/threasy"
  s.license       = "MIT"

  s.files         = %w( Gemfile README.md Rakefile LICENSE.txt threasy.gemspec )
  s.files        += Dir.glob("lib/**/*")
  s.files        += Dir.glob("spec/**/*")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.5"
  s.add_development_dependency "rake"
  s.add_development_dependency "pry"
  s.add_development_dependency "rspec"
  s.add_development_dependency "timecop"
end
