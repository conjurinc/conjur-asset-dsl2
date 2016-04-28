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

require 'conjur/api/patches/role'
require 'conjur/api/patches/user'

require 'conjur/policy/logger'
require 'conjur/policy/invalid'
require 'conjur/policy/types/base'
require 'conjur/policy/types/records'
require 'conjur/policy/types/member'
require 'conjur/policy/types/grant'
require 'conjur/policy/types/revoke'
require 'conjur/policy/types/permit'
require 'conjur/policy/types/deny'
require 'conjur/policy/types/create'
require 'conjur/policy/types/give'
require 'conjur/policy/types/retire'
require 'conjur/policy/types/update'
require 'conjur/policy/types/policy'
require 'conjur/policy/yaml/handler'
require 'conjur/policy/yaml/loader'
require 'conjur/policy/ruby/loader'
require 'conjur/policy/resolver'
require 'conjur/policy/planner'
require 'conjur/policy/executor'
require 'conjur/policy/doc'
