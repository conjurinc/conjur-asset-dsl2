require 'conjur-asset-policy-version'
require 'yaml'
require 'safe_yaml'
require 'active_support'
require 'active_support/core_ext'
SafeYAML::OPTIONS[:default_mode] = :safe
SafeYAML::OPTIONS[:deserialize_symbols] = false
   
module Conjur
  module Policy
  end
end
  
require 'rest-client'
require 'conjur-policy-parser'

require 'conjur/api/patches/role'
require 'conjur/api/patches/user'

require 'conjur/policy/planner'
require 'conjur/policy/executor'
