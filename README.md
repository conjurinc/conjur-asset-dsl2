# Conjur `dsl2` plugin

This is a Conjur plugin for a next-generation DSL, used for both policies (self contained RBAC models) and entitlements (roles and permissions which span policies and global records).

The goals of the DSL are:

* Fully declarative
* Human and machine readable
* Simplified (relative to the older Ruby DSL)
* Safe to execute in any environment

The DSL basically supports the following high-level capabilities. Each one is idempotent (it can be run repeatedly without harmful-side effects):

* **Create / Update** records, such as Role, User, and Webservice
* **Grant** roles. This basic concept covers everything from group members to adding abstract roles. Grant list can be "exclusive", which revokes the role from anyone not in the list.
* **Permit** priviliges on resources. Each permission ("transaction" in RBAC parlance) consists of a role, a privilege, and a resource. Permission list can also be "exclusive".

Also possible:

* Update ownership of a record
* Revoke roles
* Deny privileges 

# Functionality overview

## `policy`

A `policy` definition creates a versioned policy role and resource. The policy role is the owner of all new records contained with in it.

In Ruby, when a DSL is loaded as a policy, the policy record is already created an in scope. Policy fields such as `id`, `records`, `permissions` etc can be populated directly.

```ruby
policy "myapp/v1" do
	body do
		group "secrets-managers"
	
		layer "webserver"
	end
end
```

In YAML:

```yaml
- !policy
  id: myapp/v1
```

## Create and Update Records

In Ruby, record create/update is enclosed in a `records` block. Each record is created by calling a function with the record `kind`, passing the record id as the argument. Attributes and annotations can be set in a block.


```ruby
user "alice"

user "bob" do
	uidnumber 1001
	annotation "email", "bob@mycorp.com"
end
```

Here's how to create two users in YAML:

```yaml
- !user alice
- !user
  id: bob
```

The type of record that you want to create is indicated by the YAML tag. The id of the record can either be specified inline (like the first example), or as an explicit `id` field (like the second example).

## Role members

`grant` is used to grant roles, which includes group membership.

An example in which `alice` and the `ops` group are the only members of the `developers` group.

```ruby
grant do
	role group("developers")
	member user("alice")
	member group("ops)", admin:true
	exclusive true
end
```

And in YAML:


```yaml
- !grant
  role: !group developers
  members:
    - !user alice
    - 
      role: !group ops
      admin: true
  exclusive: true
```

A member is composed of the `role` (or `roles`) being granted and the `member` (or `members`) which will get the role. 

The `member` can be a plain role (again using the YAML tag to indicate the record type), if the role is granted without admin capability. To grant a role with admin, the role member is a structured entry composed of the `role` and the `admin` flag.

Note that when the `exclusive` feature is used, any existing role members that are **not** specified in the policy will be revoked. So in the example above, `!user alice` and `!group ops` will be the *only* members of `!group developers`.

## Permissions

Like `grant` is used to grant roles, `permit` is used to give permissions on a resource.

```ruby
permit %w(read execute) do
	resource variable("db-password")
	role group("developers")
	role layer("app-server")
end
	
permit "update" do
	resource variable("db-password")
	role group("developers")
	exclusive: true
end
```

```yaml
# developers group and the app-server layer are
# the only roles which can read and execute the secret.
- !permit
  resource: !variable db-password
  privilege: [ read, execute ]
  roles:
  - !group developers
  - !layer app-server
  
# developers is the only role which can update the secret.
- !permit
  resource: !variable db-password
  privilege: update
  role: !group developers
  exclusive: true
```

Use `deny` to remove a privilege without affecting the other privileges:

```ruby
deny %w(read execute) do
	resource variable("db-password")
	role layer("app-server")
end
```

In YAML:

```yaml
- !deny
  resource: !variable dev/db-password
  privilege: [ read, execute ]
  role: !layer dev/app-server
```

# Ownership

Ownership of a record (or group of records) can be assigned using the `owner` field:

```ruby
variable "db_password" do
	owner group("developers")
end
```

In YAML:

```yaml
- !variable
  id: db_password
  owner: !group developers
```

The owner tag will update both:

* **resource owner** the role will be given ownership of the `record` resource.
* **role owner** if the record has a corresponding role, the `owner` will be given the record role with `admin` option.

# Expanded discussion of design goals

This DSL format is designed to work better within automated policy management frameworks. Using these declaractive policy files, the entire authorization model of Conjur can be managed using policies.

Whenever Conjur needs to be changed, a new policy is  created or an existing policy is modified. This policy is typically managed through standard source control techniques (e.g. Git pull requests), with the security team having authority to approve and merge.

In this way, management of a Conjur system can be treated as code and leverage corresponding best pratices such as branches, pull requests, post-receive hooks, repository permissions and access rights, etc.

In addition, because the DSL format (YAML) is machine-readable, it will be straightforward to develop visual tools for editing and managing policies. Automated generation of policy files is also simple.

# Benefits

These are the benefits of the policy DSL, as imagined internally by the Conjur team:

* Large permission changes are described in a coherent way (modification of many corresponding rules can be described in single policy)
* The history of permission changes is more clear and easier to track. For example, it’s easy to list and view all policies which included references to particular ID, and understand how and why specific permissions were applied/revoked. With the current CLI it’s possible to only figure out the operations done on particular object, but not the bigger context (probably involving many corresponding changes on other objects)  in which they were applied.
* Policies can be formally validated before deployment
* Policies will implement `dry run` mode which shows the changes that will be applied to Conjur.
* Policies can be machine-generated:
	* It's easy to provision many similar assets at once
   * It's easy to generate and deploy policies from within configuration scripts
   * It will be possible and easy to write custom ‘access management’ services, which would allow users to modify some permissions and create assets in Conjur, but will be able to enforce additional fine-grained restrictions, such as id naming conventions, etc.
   * It will be possible and easy to write custom ‘policy builders’. After all, policy is just a data structure, which can be generated by any code.
* Deprovisioning of users is robust, and does not violate consistency of the database
* Export and import of permission models will be very straightforward, making it possible to implement Conjur “staging” setups.

# Examples

For many examples of sample policy files, see the [examples directory](https://github.com/conjurinc/conjur-asset-dsl2/tree/master/spec/lib/round-trip). 

# Policy conflicts

Please note that it's pretty easy to write policies which say contradictory things. For example, Policy A might use `!members` to control the members of the developers group. Another Policy B might use `!grant` to add a specific user to the developers group. When Policy B runs, it will add the user to the group. When Policy A runs, it will revoke the user. If B is run again, the user will be re-added. 

So usually good ensure that the members of a role and the privileges on a resource are managed by one approach or the other, but not both.

## Installation

Add the plugin to Conjur:

```sh-session
$ sudo -E conjur plugin install dsl2
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/conjur-asset-dsl2.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

