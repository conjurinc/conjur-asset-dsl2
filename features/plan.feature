Feature: Generating an execution plan from a policy file

  Scenario: YAML policy produces a plan
    When I plan the policy as text:
    """
    ---
    - !variable db-password
    """
    Then the normalized stdout should contain exactly:
    """
    Create variable 'db-password'
    """
      
  Scenario: YAML policy produces a plan
    When I plan the policy as yaml:
    """
    ---
    - !variable db-password
    """
    Then the normalized stdout should contain exactly:
    """
    ---
    - !create
      record: !variable
        account: cucumber
        id: db-password
        owner: !role
          account: cucumber
          id: admin
          kind: user
    """

  Scenario: --as-group option sets the owner of top-level records
    Given I load the policy "- !group ops"
    When I plan the policy as yaml with options "--as-group @namespace@/ops":
    """
    ---
    - !variable
      id: db-password
    """
    Then the normalized JSON at "0/record/id" should be "db-password"
    Then the normalized JSON at "0/record/owner/kind" should be "group"
    Then the normalized JSON at "0/record/owner/id" should be "ops"

  Scenario: --as-group option sets the owner of the policy
    Given I load the policy "- !group ops"
    When I plan the policy as yaml with options "--as-group @namespace@/ops":
    """
    ---
    - !policy
      id: myapp
      body:
        - !variable db-password
    """
    Then the normalized JSON at "0/record/id" should be "myapp"
    Then the normalized JSON at "0/record/owner/kind" should be "group"
    Then the normalized JSON at "0/record/owner/id" should be "ops"
    Then the normalized JSON at "1/record/id" should be "myapp"
    Then the normalized JSON at "1/record/owner/kind" should be "policy"
    Then the normalized JSON at "1/record/owner/id" should be "myapp"
    Then the normalized JSON at "2/record/id" should be "myapp/db-password"
    Then the normalized JSON at "2/record/owner/kind" should be "policy"
    Then the normalized JSON at "2/record/owner/id" should be "myapp"
