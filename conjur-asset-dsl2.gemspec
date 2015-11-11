# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjur-asset-dsl2-version'

Gem::Specification.new do |spec|
  spec.name          = "conjur-asset-dsl2"
  spec.version       = Conjur::Asset::DSL2::VERSION
  spec.authors       = ["Kevin Gilpin"]
  spec.email         = ["kgilpin@conjur.net"]

  spec.summary       = %q{A fully declarative DSL for Conjur with Ruby and YAML syntax.}
  spec.homepage      = "https://github.com/conjurinc/conjur-asset-dsl2"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  spec.add_dependency "safe_yaml"

  spec.add_development_dependency "conjur-cli"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
