# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'conjur-asset-policy-version'

Gem::Specification.new do |spec|
  spec.name          = "conjur-asset-policy"
  spec.version       = Conjur::Asset::Policy::VERSION
  spec.authors       = ["Kevin Gilpin"]
  spec.email         = ["kgilpin@conjur.net"]

  spec.summary       = %q{Fully declarative YAML markup for Conjur policy.}
  spec.homepage      = "https://github.com/conjurinc/conjur-asset-policy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  
  spec.add_dependency "safe_yaml"
  spec.add_dependency "conjur-policy-parser"

  spec.add_development_dependency "conjur-api", '~> 4.26'
  spec.add_development_dependency "conjur-cli"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "json_spec"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "ci_reporter_rspec"
  spec.add_development_dependency "aruba"
  spec.add_development_dependency 'io-grab'
end
