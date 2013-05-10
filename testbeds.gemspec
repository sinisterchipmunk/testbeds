# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'testbeds/version'

Gem::Specification.new do |gem|
  gem.name          = "testbeds"
  gem.version       = Testbeds::VERSION
  gem.authors       = ["Colin MacKenzie IV"]
  gem.email         = ["sinisterchipmunk@gmail.com"]
  gem.description   = "Manage multiple testbed environments for your gems"
  gem.summary       = "Manage multiple testbed environments for your gems"
  gem.homepage      = "http://github.com/sinisterchipmunk/testbeds"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
