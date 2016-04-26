Feature: $namespace token can be used to link policies within the same namespace.

  Scenario: Assign ownership of a record inside a policy
    Given I load the policy with options "--namespace dev/@namespace@":
    """
    ---
    - !group @namespace@/a
    """
    And I plan the policy as yaml with options "--namespace dev/@namespace@":
    """
    ---
    - !group 
      id: @namespace@/b
      owner: !group /$namespace/a
    """
    Then the normalized stdout should contain:
    """
    ---
    - !create
      record: !group
        account: cucumber
        id: dev/b
        owner: !group
          account: cucumber
          id: dev/a
    """
