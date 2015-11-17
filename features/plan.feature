Feature: Generating an execution plan from a policy file

  Scenario: Ruby policy produces a plan
    When I plan the policy as text:
    """
    variable "foobar"
    """
    Then the stdout should contain exactly:
    """
    Create variable foobar
    """
      
  Scenario: YAML policy produces a plan
    When I plan the policy as yaml:
    """
    variable "foobar"
    """
    Then the stdout should contain exactly:
    """
    ---
    - service: directory
      type: variable
      action: create
      path: variables
      parameters:
        id: foobar
        mime_type: text/plain
        kind: secret
      description: Create variable foobar
      """
