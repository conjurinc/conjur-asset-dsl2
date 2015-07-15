module Conjur
  module DSL2
    module Actions
      class Permit
        attr_reader :api
        
        def perform config
          Array(config.resource).each do |r|
            resource = api.resource(resourceid(r.resource))
            Array(config.privilege).each do |p|
              Array(config.member).each do |m|
                role = api.role(roleid(m.role))
                options = {}.tap do |o|
                  o[:grant_option] = true unless m.admin.nil?
                end
                resource.permit privilege, role, options
              end
            end
          end
        end
      end
    end
  end
end
