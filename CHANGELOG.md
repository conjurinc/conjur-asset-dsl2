# 0.8.0

* **Breaking change** Removed `--syntax` flag from `policy load`. Only YML is supported going forwards.
* `policy load` writes changes to be made to stderr before making them.

# 0.7.1

* Fix botched gem release.

# 0.7.0

* Renamed plugin from 'dsl2' to 'policy'
* Added 'retire' subcommand

# 0.6.1

* Properly format the Host Factory layers as they are submitted to the server.
* Properly report role or resource missing errors.
* Host Factory role defaults to its owner.

# 0.6.0

* Implement the !deny statement.
* Eliminate un-necessary privilege and role revocations.

# 0.5.0

* Refactor how the policy statements are validated and normalized, fixing some bugs in the process.
* In record ids, replace the string '$namespace' with the policy namespace. This enables cross-policy
  entitlements to be made more flexibly. 

# 0.4.4

* Enable immutable attributes to be set when the value is unchanged.

# 0.4.3

* Fix a load error which can occur when using YAML lists inside of policies.

# 0.4.2

* Support `--context` flag to save API keys to a file.

# 0.3.2

* Fix issue where webservices were being treated as core assets by the executor.

# 0.3.1

* Fix bug in executor for permissions.

# 0.3.0
 
* Initial stable version.
