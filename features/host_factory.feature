Feature: Host factory parameters are handled properly.

  Scenario: Layers list is sent to the server with Rails-style array[] parameter keys
    Given I load the policy:
    """
    ---
    - !policy
      id: test
      body:
      - !layer
      - !host-factory
        layers: [ !layer ]
    """
    Then the host factory layers should be exactly [ 'test' ]
