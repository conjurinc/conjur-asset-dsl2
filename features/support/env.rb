$LOAD_PATH.unshift File.expand_path('../..', File.dirname(__FILE__))

require 'cucumber'
require 'aruba/cucumber'
require 'conjur/cli'

Conjur::Config.load
Conjur::Config.apply
$conjur = Conjur::Authn.connect nil, noask: true
