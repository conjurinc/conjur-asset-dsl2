Feature: owner field can assign ownership of a new or existing record

  Scenario: Assign ownership of a record inside a policy
    Given I load the policy:
    """
    ---
    - !policy
      id: test
      body:
      - !group a
      - !group b
      - !layer
        owner: !group a
    """
    When I plan the policy as yaml:
    """
    ---
    - !policy
      id: test
      body:
      - !group a
      - !group b
      - !layer
        owner: !group b
    """
    Then the normalized stdout should contain:
    """
    ---
    - !give
      owner: !role
        account: cucumber
        id: test/b
        kind: group
      resource: !resource
        account: cucumber
        id: test
        kind: layer
    - !grant
      member: !member
        admin: true
        role: !role
          account: cucumber
          id: test/b
          kind: group
      role: !role
        account: cucumber
        id: test
        kind: layer
    """

  Scenario: Ownership of top-level objects can be changed by re-loading the policy.
    Given I load the policy:
    """
    ---
    - !group
      id: ops
    - !group
      id: test
    """
    When I plan the policy as text with options "--as-role group:@namespace@/ops":
    """
    ---
    - !group
      id: @namespace@/test
    """
    Then the normalized stdout should contain exactly:
    """
    {}
    Give group resource 'test' to group role 'ops'
    Grant group role 'test' to group role 'ops' with admin option
    """

  Scenario: Ownership of policy roles can be changed by re-loading the policy.
    Given I load the policy:
    """
    ---
    - !group
      id: ops
    - !policy
      id: test
      body: []
    """
    When I plan the policy as text with options "--as-role group:@namespace@/ops":
    """
    ---
    - !policy
      id: @namespace@/test
      body: []
    """
    Then the normalized stdout should contain exactly:
    """
    {}
    Grant policy role 'test' to group role 'ops' with admin option
    """
