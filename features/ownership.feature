Feature: owner field can assign ownership of a new or existing record

  Scenario: Assign ownership of a record inside a policy
    When I plan the policy as yaml:
    """
    ---
    - !policy
      id: @namespace@/test
      body:
      - !group
        id: a
      - !layer
        owner: !group a
    """
