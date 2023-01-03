# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'specr/version'

Gem::Specification.new do |spec|
  spec.name          = 'specr'
  spec.version       = Specr::VERSION
  spec.authors       = ['Ben Mills']
  spec.email         = ['ben@unfiniti.com']

  spec.summary       = 'A toolkit for building API specifications.'
  spec.description   = 'A toolkit for building API specifications.'
  spec.homepage      = 'http://github.com/remear/specr'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'cucumber', '~> 2.4.0'
  spec.add_dependency 'httparty', '>= 0.18', '< 0.22'
  spec.add_dependency 'json-schema', '~> 2.6'
  spec.add_dependency 'test-unit'
  spec.add_dependency 'rake', '~> 10.0'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rubocop', '~> 0.40.0'
end
