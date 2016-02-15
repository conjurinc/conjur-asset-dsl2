Feature: Some attributes are flagged as immutable

  Scenario: An immutable attribute cannot be updated
    Given I load the policy:
    """
    - !variable
      id: @namespace@/password
      kind: password
    """
    When I try to plan the policy as yaml:
    """
    - !variable
      id: @namespace@/password
      kind: db-password
    """
    Then the plan should not succeed
    Then the stderr should contain "Cannot modify immutable attribute"

  Scenario: An immutable attribute can be left unchanged
    Given I load the policy:
    """
    - !variable
      id: @namespace@/password
      kind: password
    """
    Then I plan the policy as yaml:
    """
    - !variable
      id: @namespace@/password
      kind: password
    """
