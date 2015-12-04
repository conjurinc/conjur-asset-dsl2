# Conjur DSL2 YAML Syntax

## Nomenclature

We refer to any element of a policy document that may occur in a top level sequence or
in the `body` field of a `policy` as a *top level element*.  Note that a `policy` is a 
`top level element`.  

We use terms such as `anchor`, `sequence`, `mapping`, and `scalar`, as well as commonly understood types such
as `string`s and `integer`s in their usual sense with respect to the YAML language.

## Policy Documents

A policy document is a file containing a description (perhaps partial) of the desired state of a Conjur
permissions model.

A policy document used by Conjur DSL2 can be either a **sequence** of *top level elements*, or a `policy` declaration.

### `policy` Element 

A policy definition has the following form:

```yaml
policy:
  id: "my-policy-id"
  body:
    # sequence of top level elements
```

A policy element creates a `policy` resource and role.  The *role* will be the default owner of all records created in
the policy.  The resource can be used to grant permissions on the policy as a whole.  The `id` of the policy is prefixed 
to the id of all records created in the `body` of the policy.  If a policy has `id` `"foo"` and a record is created in its
body with id `"bar"`, the record will have an `id` of `"foo/bar"`.

A policy has the following children:
    * `id`: the policy id as a string. Required.
    * `body`: a *sequence* of top-level elements contained by the policy.  Required.
        **Note** the body may contain other `policy` elements, but this is generally considered bad practice.
             
### Records

A record element is used to create or update a Conjur asset, such as a `group`, `user`, `webservice`, or `host_factory`.

If a policy is loaded containing a record that already exists, that record will be updated if any of its mutable
attributes have changed.  If it does not exist, it will be created with the defined attributes.

All **record** elements share the following members:

  * `id`: the identifier for the record as a string. Required.
  * `annotations`: A yaml `Mapping` of annotation keys to annotation values, as strings.
  * `owner`: a reference to a Conjur role that should be the `owner` of this record.
  * `account`: a record can specify an explicit Conjur account. You should generally not
    have to use this.
  


Create a user with id `'alice'` and an annotation:
```yaml
- !user
  id: alice
  annotations:
    hair-color: blonde
```

#### User records

In addition to the standard record members, users can have an optional `uidnumber`.  This is used for SSH login and certain 
LDAP features, and must be globally unique.

```yaml
- !user
    id: bob
    uidnumber: 123
```

#### Group records

In addition to the standard record members, groups can have an optional `gidnumber`.  This is used for SSH login and
certain LDAP features. It need not be unique.

```yaml
- !group
    id: ops
    gidnumber: 5050
```

#### Host, Layer, and Webservice records

These records have no special attributes.

#### Variable Records

In addition to the standard record members, variables support the following members:
    
  * `kind` A human-friendly description of the kind of secret stored in this variable, e.g. 'database uri'
  * `mime_type` A **MIME Type** string used when serving the contents of this variable via HTTP.

Note that both of these attributes are immutable once the variable has been created.


