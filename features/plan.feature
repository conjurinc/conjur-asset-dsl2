Feature: Generating an execution plan from a policy file

  Scenario: Ruby policy produces a plan
    When I plan the policy as text:
    """
    variable "db-password"
    """
    Then the normalized stdout should contain exactly:
    """
    Create variable db-password
    """
      
  Scenario: YAML policy produces a plan
    When I plan the policy as yaml:
    """
    variable "db-password"
    """
    Then the normalized stdout should contain exactly:
    """
    ---
    - service: directory
      type: variable
      action: create
      path: variables
      parameters:
        id: db-password
        mime_type: text/plain
        kind: secret
      description: Create variable db-password
      """

  Scenario: --as-group option sets the owner of top-level records
    Given I load the policy "group 'ops'"
    When I plan the policy as yaml with options "--as-group @namespace@/ops":
    """
    variable "db-password"
    """
    Then the normalized JSON at "0/parameters/id" should be "db-password"
    Then the normalized JSON at "0/parameters/ownerid" should be "cucumber:group:ops"

  Scenario: --as-group option sets the owner of the policy
    Given I load the policy "group 'ops'"
    When I plan the policy as yaml with options "--as-group @namespace@/ops":
    """
    policy "myapp" do
      body do
        variable "db-password"
      end
    end
    """
    Then the normalized JSON should have 3 items
    Then the normalized JSON at "0/id" should be "cucumber:policy:myapp"
    Then the normalized JSON at "0/type" should be "role"
    Then the normalized JSON at "0/parameters/acting_as" should be "cucumber:group:ops"
    Then the normalized JSON at "1/id" should be "cucumber:policy:myapp"
    Then the normalized JSON at "1/type" should be "resource"
    Then the normalized JSON at "1/parameters/acting_as" should be "cucumber:policy:myapp"
    Then the normalized JSON at "2/parameters/id" should be "myapp/db-password"
    Then the normalized JSON at "2/type" should be "variable"
    Then the normalized JSON at "2/parameters/ownerid" should be "cucumber:policy:myapp"
