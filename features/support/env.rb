require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/features/'
end

$LOAD_PATH.unshift File.expand_path('../..', File.dirname(__FILE__))

require 'cucumber'
require 'aruba/cucumber'
require 'json_spec/cucumber'
require 'conjur/cli'

Conjur::Config.load
Conjur::Config.apply
$conjur = Conjur::Authn.connect nil, noask: true

$timestamp = Time.now.strftime("%Y%jT%H%MZ")
