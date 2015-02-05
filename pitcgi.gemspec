# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'pitcgi/version'
require 'pitcgi'

Gem::Specification.new do |gem|
  gem.name          = Pitcgi::NAME
  gem.version       = Pitcgi::VERSION
  gem.authors       = ["sanadan"]
  gem.licenses      = ['Ruby']
  gem.email         = ["jecy00@gmail.com"]
  gem.description   = %q|pitcgi: account management tool for cgi|
  gem.summary       = %q|pitcgi: account management tool for cgi|
  gem.homepage      = "https://github.com/sanadan/pitcgi"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.0.0'
end
