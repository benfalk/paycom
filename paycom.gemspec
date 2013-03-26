# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paycom/version'
require 'net/http'
require 'net/https'

Gem::Specification.new do |gem|
  gem.name          = 'paycom'
  gem.version       = Paycom::VERSION
  gem.authors       = ['Benjamin Falk']
  gem.email         = ['benjamin.falk@yahoo.com']
  gem.description   = %q{Used to do basic interaction with the unsightly Paycom website}
  gem.summary       = %q{Crude Paycom Lib}
  gem.homepage      = 'https://github.com/benfalk/paycom'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'activesupport'
end
