Feature: Public keys can be managed via policy.

  Scenario: New public keys are registered
    Given I load the policy:
    """
    ---
    - !user
      id: alice
      public_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRTgZ8nRvTNdS1f/UD3xi3Q6APvTJiXXRYGlJyTLixJj0+e/iKHNLW7Nz57vkziQXvWrM0x4PftTZytqvzyr0Ehbkl2lSrB5NMS2l1027qrOr4+/CoOk37nQ53XFyv4POB3mj6MOzzzemlv27iA6A9+Z+XjCPFSjlgxCpjPfr/jAB4BGrak3+r/hwRW1ymoQY5AdRxtA84D44xQF19mza2JmVDY5DQJwMf2bDq/+wnB9NyhjLdAF3TFFOhe7tbqbO3RNm5sHARjYtdLgPkd1XLQAfBbQn8CCUKDSx5IazCjHCftJKyTVATx1QrHRjpbdyUG08c+2VR7E+10trhK5Pt kevin@home
    """
    Then the public keys for "alice" should be exactly:
    """
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRTgZ8nRvTNdS1f/UD3xi3Q6APvTJiXXRYGlJyTLixJj0+e/iKHNLW7Nz57vkziQXvWrM0x4PftTZytqvzyr0Ehbkl2lSrB5NMS2l1027qrOr4+/CoOk37nQ53XFyv4POB3mj6MOzzzemlv27iA6A9+Z+XjCPFSjlgxCpjPfr/jAB4BGrak3+r/hwRW1ymoQY5AdRxtA84D44xQF19mza2JmVDY5DQJwMf2bDq/+wnB9NyhjLdAF3TFFOhe7tbqbO3RNm5sHARjYtdLgPkd1XLQAfBbQn8CCUKDSx5IazCjHCftJKyTVATx1QrHRjpbdyUG08c+2VR7E+10trhK5Pt kevin@home
    """
