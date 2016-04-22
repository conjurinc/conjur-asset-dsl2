# coding: utf-8
module Conjur
  module Policy
    module Types
      # A createable record type.
      class Record < Base
        def role?
          false
        end
        def resource?
          false
        end
      end
      
      module ActsAsResource
        def self.included(base)
          base.module_eval do
            attribute :id,   kind: :string, singular: true, dsl_accessor: true
            attribute :account, kind: :string, singular: true
            attribute :owner, kind: :role, singular: true, dsl_accessor: true
            
            attribute :annotations, kind: :hash, type: Hash, singular: true
            
            def description value
              annotation 'description', value
            end
            
            def annotation name, value
              self.annotations ||= {}
              self.annotations[name] = value
            end
          end
        end
        
        def initialize id = nil
          self.id = id if id
        end
        
        def to_s
          "#{resource_kind.gsub('_', ' ')} '#{id}'#{account && account != Conjur.configuration.account ? ' in account \'' + account + '\'': ''}"
        end
        
        def resourceid default_account = nil
          [ account || default_account, resource_kind, id ].join(":")
        end
        
        def resource_kind
          self.class.name.split("::")[-1].underscore
        end

        def resource_id
          id
        end
        
        def action
          :create
        end
        
        def resource?
          true
        end
        
        def immutable_attribute_names
          []
        end

      end
      
      module ActsAsRole
        def roleid default_account = nil
          [ account || default_account, role_kind, id ].join(":")
        end
        
        def role?
          true
        end
        
        def role_kind
          self.class.name.split("::")[-1].underscore
        end
        
        def role_id
          id
        end
      end
      
      module ActsAsCompoundId
        def initialize kind_or_id = nil, id_or_options = nil
          if kind_or_id && id_or_options && id_or_options.is_a?(String)
            self.kind = kind_or_id
            self.id = id_or_options
          elsif kind_or_id && kind_or_id.index(":")
            id_or_options ||= {}
            account, self.kind, self.id = kind_or_id.split(':', 3)
            self.account = account if account != id_or_options[:default_account]
          end
        end

        def == other
          other.kind_of?(ActsAsCompoundId) && kind == other.kind && id == other.id && account == other.account
        end

        def to_s
          "#{kind} #{self.class.short_name.underscore} '#{id}'#{account && account != Conjur.configuration.account ? ' in account \'' + account + '\'': ''}"
        end
      end
      
      class Role < Record
        include ActsAsRole
        include ActsAsCompoundId
        
        attribute :id,   kind: :string, singular: true, dsl_accessor: true
        attribute :kind, kind: :string, singular: true, dsl_accessor: true
        attribute :account, kind: :string, singular: true
        attribute :owner, kind: :role, singular: true, dsl_accessor: true

        self.description = %(
Create a custom role.

From our [role-based access control guide](/key_concepts/rbac.html):

> The purpose of a role is to have privileges and to initiate
> transactions.
> 
> A role may represent a person, a group, a non-human user (“robot”)
> such as a virtual machine or process, or a group of other roles.
> 
> In addition to having privileges, a role can be granted to another
> role.
> 
> When a role is granted, the receiving role gains all the privileges
> of the granted role. In addition, it gains all the roles which are
> held by the granted role; role grants are fully inherited.

)

        self.example = %(
- !user Beowulf

- !role tragic_end
    kind: destiny
    owner: !user Beowulf
)

        def roleid default_account = nil
          raise "account is required" unless account || default_account
          [ account || default_account, kind, id ].join(":")
        end
        
        def role_id; id; end
        def role_kind; kind; end
                  
        def immutable_attribute_names
          []
        end
      end
      
      class Resource < Record
        include ActsAsResource
        include ActsAsCompoundId

        attribute :kind, kind: :string, singular: true, dsl_accessor: true

        self.description = %(
Create a custom Resource.

From our [role-based access control guide](/key_concepts/rbac.html):

> Resources are the entities on which permissions are defined. A
> resource id is an arbitrary, unique string which identifies the
> protected asset.
> 
> Examples: database password, virtual machine or
> server (for SSH access management), web service endpoint

From our [CLI reference](/cli#annotating-resources):

> Any Conjur resource can be annotated with a key-value pair. This
  makes organization and discovery easier since annotations can be
  searched on and are shown in the Conjur UI. Automation workflows
  like rotation and expiration are based on annotations.

)

        self.example = %(
- !user nobody

- !resource unicorn
    kind: magical_beast
    annotations:
      has_deadly_horn: true
      has_mercy: false
    owner: !user nobody
)

        def resource_kind
          kind
        end
      end
      
      class User < Record
        include ActsAsResource
        include ActsAsRole
        
        self.description = %(
Create a [Role](#reference/role) representing a human user. (For virtual machines, scripts, and other infrastructure, [Host](#reference/host) is a more appropriate role.)

See also: [Users](/reference/services/directory/user) in our service reference.
)

        self.example = %(
- !user robert
    uidnumber: 1208
    annotations:
      public: true
      can_predict_movement: false
)
        
        attribute :uidnumber, kind: :integer, singular: true, dsl_accessor: true
        
        def id_attribute; 'login'; end
        
        def custom_attribute_names
          [ :uidnumber ]
        end
      end
      
      class Group < Record
        include ActsAsResource
        include ActsAsRole
        
        attribute :gidnumber, kind: :integer, singular: true, dsl_accessor: true

        self.description = %(
Create a Group record.

From our [CLI reference](/cli#users-groups):

> Users are organized into groups in Conjur. Every user other than
  'admin' should be in a group. When a user becomes a member of a
  group they inherit the group's privileges. You can delegate members
  of the group to be admins. This means that they can add and remove
  other members of the group. The owner of a group is automatically an
  admin.

See also: [User](#reference/user) type, [Groups](/reference/services/directory/group) in our service reference.
)

        self.example = %(
- !user sysop
- !user db-admin

- !group ops
    gidnumber: 110

- !grant
    role: !group ops
    members:
    - !user sysop
    - !member
        role: !user db-admin
        admin: true
)
        def custom_attribute_names
          [ :gidnumber ]
        end
      end
      
      class Host < Record
        include ActsAsResource
        include ActsAsRole

        self.description = %(
Create a Host record and resource.

See also: [Layer](#reference/layer) type, [machine identity](/key_concepts/machine_identity.html), [Host](/reference/services/directory/host) in our service reference.
)

        self.example = %(
- !group CERN

- !host httpd
    annotations:
      descripton: hypertext web server
      started: 1990-12-25
      owner: !group CERN
)
      end
      
      class Layer < Record
        include ActsAsResource
        include ActsAsRole

        self.description = %(
Create a Layer record.

From our [CLI reference](/cli#hosts-layers):

> Host are organized into layers in Conjur. Hosts can be added and
  removed from layers, and map logically to your infrastructure. A
  host can be a single machine, but it could also be an application or
  Docker container - where several different applications are running
  on the same machine or VM.

See also: [Host](#reference/host) type, [Layers](/reference/services/directory/layer) in our service reference.
)

        self.example = %(
- !host ProteusIV
- !host AM
- !host GLaDOS

- !layer bad_hosts

- !grant
    role: !layer bad_hosts
    members:
      - !host ProteusIV
      - !host AM
      - !host GLaDOS
)
      end
      
      class Variable < Record
        include ActsAsResource
        
        attribute :kind,      kind: :string, singular: true, dsl_accessor: true
        attribute :mime_type, kind: :string, singular: true, dsl_accessor: true

        self.description = %(
Create a Variable resource to hold a secret value.

From our [CLI reference](/cli#variables):

> Variables are containers for secrets in Conjur. They can hold any
> value. You can annotate resources and also assign them a kind, a
> signifier as to what type of value they hold. Variable values are
> versioned and assigning a value during variable creation is
> optional. When fetching a value, the latest version is returned by
> default.
> 
> Variables are resources; you assign roles privileges to them as
> desired.

See also: [Variables](https://developer.conjur.net/reference/services/directory/variable) in the service reference.
)

        self.example = %(
- !variable spoiler
    kind: utf-8
    mime-type: x/json
)

        def custom_attribute_names
          [ :kind, :mime_type ]
        end
        
        def immutable_attribute_names
          [ :kind, :mime_type ]
        end
      end
      
      class Webservice < Record
        include ActsAsResource

        self.description = %(
Create a [Resource](#reference/resource) representing a web service endpoint.

From our [role-based access control guide](/key_concepts/rbac.html):

> Web services endpoints are represented in Conjur as a webservice
> resource. Permission grants are pretty straightforward: an input
> HTTP request path is mapped to a webservice resource. The HTTP
> method is mapped to an RBAC privilege. A permission check is
> performed, according to the following transaction:
> 
> * `role` incoming role on the HTTP request
> * `privilege` read, update, or delete according to HTTP verb
> * `resource` web service resource id

)

        self.example = %(
- !group analysts
- !webservice xkeyscore
    annotations:
      description: API endpoint for surveillance apparatus

- !permit
    role: !group analysts
    privilege: read
    resource: !webservice xkeyscore
)
      end
      
      class HostFactory < Record
        include ActsAsResource

        self.description = %(
Create a host-factory service for bootstrapping [Hosts](#reference/host) into a [Layer](#reference/layer).

See also: [Host Factory](/reference/services/host_factory) in our service reference.
)

        self.example = %(
- !layer nest

- !host-factory
    annotations:
      description: Factory to create new bird hosts
    layers: [ !layer nest ]
)
        
        attribute :role, kind: :role, dsl_accessor: true, singular: true
        attribute :layer, kind: :layer, dsl_accessor: true
        
        alias role_accessor role
        
        def role *args
          if args.empty?
            role_accessor || self.owner
          else
            role_accessor(*args)
          end
        end
      end
      
      class AutomaticRole < Base
        include ActsAsRole
        
        def initialize record = nil, role_name = nil
          self.record = record if record
          self.role_name = role_name if role_name
        end
        
        attribute :record,    kind: :role,   singular: true
        attribute :role_name, kind: :string, singular: true

        self.description = %(
Some [Roles](#reference/role) are created automatically. These are accessed by using the `automatic-role`
type, which identifies the containing record (e.g. a Layer), and the name of the automatic role (e.g. `use_host`).

These roles are:

* `use_host`, for allowing SSH access
* `admin_host`, for allowing admin (root) login.
* `observe`
)

        self.example = %(
- !user chef
- !user owner
- !group line-cooks
- !layer kitchen

# no need to create MangedRoles; they are automatic.

- !grant
    role: !automatic-role
      record: !layer kitchen
      role_name: use_host
    member: !group line-cooks

- !grant
    role: !automatic-role
      record: !layer kitchen
      role_name: admin_host
    member: !user chef

- !grant
    role: !automatic-role
      record: !layer kitchen
      role_name: observe
    member: !user owner
)
        
        class << self
          def build fullid
            account, kind, id = fullid.split(':', 3)
            raise "Expecting @ for kind, got #{kind}" unless kind == "@"
            id_tokens = id.split('/')
            record_kind = id_tokens.shift
            role_name = id_tokens.pop
            record = Conjur::Policy::Types.const_get(record_kind.classify).new.tap do |record|
              record.id = id_tokens.join('/')
              record.account = account
            end
            self.new record, role_name
          end
        end
        
        def to_s
          role_name = self.id.split('/')[-1]
          "'#{role_name}' on #{record}"
        end
        
        def account
          record.account
        end
        
        def role_kind
          "@"
        end
        
        def id
          [ record.role_kind, record.id, role_name ].join('/')
        end
      end
    end
  end
end
