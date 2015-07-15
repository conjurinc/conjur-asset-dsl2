$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'conjur-asset-dsl2'

if ENV['DEBUG'] == 'true'
  Conjur::DSL2::Handler.logger.level = Logger::DEBUG
end