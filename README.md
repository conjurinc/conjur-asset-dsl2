# Conjur `dsl2` plugin

This is a Conjur plugin for a next-generation policy DSL.

The goals of the DSL are:

* Fully declarative
* Human and machine readable
* Simplified (relative to the older Ruby DSL)
* Safe to execute in any environment

The DSL basically supports the following high-level capabilities. Each one is idempotent (it can be run repeatedly without harmful-side effects):

* **Create** new records, such as Role, User, and Webservice
* **Ownership** assignment.
* **Members** of roles. This basic concept covers everything from group members to adding abstract roles.
* **Permissions** on resources. Each permission ("transaction" in RBAC parlance) consists of a role, a privilege, and a resource. 

## `!policy`

TODO: A `!policy` definition creates a versioned policy role and resource. The policy role is the owner of all new records. This is not yet implemented, but it may look something like this:

```yaml
# Create a policy which will own the new records
- !policy
  id: myapp
  version: 1.0
```

(There may be only one `!policy` per policy file, and it should be the first entry).

## Creation

Here's how to create two users using a YAML policy:

```yaml
# Create users named alice and bob
- !user alice
- !user
  id: bob
```

The type of record that you want to create is indicated by the YAML tag. The id of the record can either be specified inline (like the first example), or as an explicit `id` field (like the second example).

## Role members

An example:

```yaml
# alice and the ops group are the only members of the 
# developers group.
- !members
  role: !group developers
  members:
    - !user alice
    - 
      role: !group ops
      admin: true

```

A member is composed of the `role` (or `roles`) being granted and the `member` (or `members`) which will get the role. 

The `member` can be a plain role (again using the YAML tag to indicate the record type), if the role is granted without admin capability. To grant a role with admin, the role member is a structured entry composed of the `role` and the `admin` flag.

Note that when the `members` feature is used, any existing role members that are **not** specified in the policy will be revoked. So in the example above, `!user alice` and `!group ops` will be the *only* members of `!group developers`.

To add or remove a role member without affecting the other members, use `!grant`  or `!revoke` instead. For example:

```yaml
# Add alice to the developers group without affecting
# the other members.
- !grant
  role: !group developers
  member: !user alice
```

## Permissions

Like `!members`, `!permissions` is used to control the entire set of permissions on a resource.

```yaml
# developers group and the dev/app-server layer are
# the only roles which can read and execute the secret.
- !permissions
  resource: !variable dev/db-password
  privilege: [ read, execute ]
  roles:
  - !group developers
  - !layer dev/app-server
  
# developers is the only role which can update the secret.
- !permissions
  resource: !variable dev/db-password
  privilege: update
  role: !group developers
```

Use `!permit` or `!deny` to add or remove a privilege without affecting the other privileges:

```yaml
# Allow the dev/app-server layer to read and execute
# the dev/db-password.
- !permit
  resource: !variable dev/db-password
  privilege: [ read, execute ]
  role: !layer dev/app-server
```

# Ownership

Ownership of a record (or group of records) can be assigned using the `!owner` tag:

```yaml
- !owner
  record: !variable db_password
  owner: !group developers
```

The owner tag will update both:

* **resource owner** the role will be given ownership of the `record` resource.
* **role owner** if the record has a corresponding role, the `owner` will be given the record role with `admin` option.

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

