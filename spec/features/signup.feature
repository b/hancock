Feature: Signing Up for an SSO Account
  Scenario: Signup with an initial return_to parameter
    Given I do not have a valid session on the server
    And a valid consumer and user exists
    When I request authentication returning to a consumer app
    Then I should see the login form
    When I click signup
    Then I should see the signup form
    When I signup with valid info
    Then I should receive a registration url
    When I hit the registration url and provide a password
    Then I should be redirected to the consumer app

  Scenario: Signup without a return_to parameter
    Given I do not have a valid session on the server
    And a valid consumer and user exists
    Given I request authentication
    Then I should see the login form
    When I click signup
    Then I should see the signup form
    When I signup with valid info
    Then I should receive a registration url
    When I hit the registration url and provide a password
