module Conjur
  module DSL2
    module Actions
      class Permissions
        attr_reader :api
        
        Permission = Struct.new(:privilege, :grant_option, :resourceid, :roleid)
        
        def perform config
          Array(config.resource).each do |r|
            resource = api.resource(resourceid(r.resource))
            # {
            #   "privilege": "read",
            #   "grant_option": false,
            #   "resource": "conjurops:group:v4/developers",
            #   "role": "conjurops:user:apotter",
            #   "grantor": "conjurops:user:kgilpin"
            # }
            existing_permissions = resource['permissions'].map do |p|
              Permission.new(p['privilege'], p['grant_option'], p.resourceid, p.roleid)
            end
            requested_permissions = []
            Array(config.privilege).each do |p|
              Array(config.member).each do |m|
                role = api.role(roleid(m.role))
                requested_permissions.push Permission.new(p, m.admin || false, resource.resourceid, role.roleid)
              end
            end
            give_permissions = requested_permissions - existing_permissions
            deny_permissions = existing_permissions - requested_permissions
            give_permissions.each do |p|
              Permit.new(api).perform p
            end
            deny_permissions.each do |p|
              Deny.new(api).perform p
            end
          end
        end
      end
    end
  end
end
