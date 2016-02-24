Feature: owner field can assign ownership of a new or existing record

  Scenario: Assign ownership of a record inside a policy
    Given I load the policy:
    """
    ---
    - !policy
      id: @namespace@/test
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
      id: @namespace@/test
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
