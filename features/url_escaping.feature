Feature: Tricky URLs are properly escaped/encoded

  Scenario: Granting to a role which has a space in the name
    Then I load the policy:
    """
    - !group ops
    - !group Domain Controllers
    - !grant
      role: !group ops
      member: !group Domain Controllers
    """
    Then the group "Domain Controllers" belongs to the group "ops"

  Scenario: Granting a role which has a space in the name
    Then I load the policy:
    """
    - !group ops
    - !group Domain Controllers
    - !grant
      role: !group Domain Controllers
      member: !group ops
    """
    Then the group "ops" belongs to the group "Domain Controllers"

  Scenario: Revoking from a role which has a space in the name
    When I load the policy:
    """
    - !group ops
    - !group Domain Controllers
    - !grant
      role: !group ops
      member: !group Domain Controllers
    """
    Then I load the policy:
    """
    - !group ops
    - !group Domain Controllers
    - !revoke
      role: !group ops
      member: !group Domain Controllers
    """
    Then the groups "Domain Controllers" and "ops" have no relationship

  Scenario: Revoking a role which has a space in the name
    When I load the policy:
    """
    - !group ops
    - !group Domain Controllers
    - !grant
      role: !group Domain Controllers
      member: !group ops
    """
    Then I load the policy:
    """
    - !group ops
    - !group Domain Controllers
    - !revoke
      role: !group Domain Controllers
      member: !group ops
    """
    Then the groups "Domain Controllers" and "ops" have no relationship
