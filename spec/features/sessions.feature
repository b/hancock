Feature: Logging In to an SSO Account
  In order to authenticate existing users
  As an existing user
    Scenario: logging in as a redirect from a consumer
      Given I am not logged in on the sso provider
      And a valid consumer and user exists
      When I request authentication returning to the consumer app
      Then I should see the login form
      When I login
      Then I should be redirected to the consumer app to start the handshake
    Scenario: logging in
      Given I am not logged in on the sso provider
      And a valid consumer and user exists
      When I request authentication
      Then I should see the login form
      When I login
      Then I should be redirected to the sso provider root on login
