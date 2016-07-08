Feature: Planning can do existence and adminship checks

  Scenario: Planning sees an existing record
    Given I load the policy "- !group ops"
    When I plan the policy as yaml:
    """
    ---
    - !group ops
    """
    Then the normalized stdout should contain "--- []"

  Scenario: Planning sees an existing resource
    Given I load the policy:
    """
    ---
    - !resource
      id: webservice1
      kind: webservice
    """
    When I plan the policy as yaml:
    """
    ---
    - !resource 
      id: webservice1
      kind: webservice
    """
    Then the normalized stdout should contain "--- []"

  Scenario: Planning sees an existing role
    Given I load the policy:
    """
    ---
    - !role
      id: service
      kind: robot
    """
    When I plan the policy as yaml:
    """
    ---
    - !role
      id: service
      kind: robot
    """
    Then the normalized stdout should contain "--- []"

  @announce-output
  Scenario: Planning sees an owner as an admin
    Given I load the policy:
    """
    ---
    - !user owner
    - !group
      id: ops
      owner: !user owner
    """
    When I plan the policy as yaml:
    """
    ---
    - !grant
      role: !group ops
      members:
        - !member
          role: !user owner
          admin: true        
    """
    Then the normalized stdout should contain "--- []"

  Scenario: Planning sees an existing adminship
    Given I load the policy:
    """
    ---
    - !user owner
    - !group
      id: ops
    - !grant
      role: !group ops
      members:
        - !member
          role: !user owner
          admin: true        

    """
    When I plan the policy as yaml:
    """
    ---
    - !grant
      role: !group ops
      members:
        - !member
          role: !user owner
          admin: true        
    """
    Then the normalized stdout should contain "--- []"
