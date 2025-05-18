require "test_helper"

module Users
  class AuthServiceTest < ActiveSupport::TestCase
    setup do
      company = Company.create!(
        trader_name: "Test Company",
        entity_attributes: {
          registration_number: "12345678901234",
          registration_type: "cnpj"
        }
      )
      @user = User.create!(
        email: "existing@example.com",
        first_name: "Valid",
        last_name: "User",
        company_id: company.id
      )

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should raise User not found error when user does not exist in the database" do
      email = "nonexistent@example.com"
      password = "password123"

      assert_nil User.find_by(email: email)

      result = assert_raises(ActiveRecord::RecordNotFound) do
        AuthService.call(email: email, password: password)
      end

      assert_equal "User not found", result.message
    end

    test "should raise Invalid credentials error when Cognito returns NotAuthorizedException" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "wrong_password",
            "SECRET_HASH" => Users::AuthService.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, "Invalid credentials"))
        .once

      result = assert_raises(StandardError) do
        AuthService.call(email: @user.email, password: "wrong_password")
      end

      assert_equal "Invalid credentials", result.message
    end

    test "should raise User not found error when Cognito returns UserNotFoundException" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "wrong_password",
            "SECRET_HASH" => Users::AuthService.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new(nil, "User not found"))
        .once

      result = assert_raises(ActiveRecord::RecordNotFound) do
        AuthService.call(email: @user.email, password: "wrong_password")
      end

      assert_equal "SCIM: User not found", result.message
    end

    test "should raise Password reset required error when Cognito returns PasswordResetRequiredException" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "wrong_password",
            "SECRET_HASH" => Users::AuthService.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::PasswordResetRequiredException.new(nil, "Password reset required"))
        .once

      result = assert_raises(StandardError) do
        AuthService.call(email: @user.email, password: "wrong_password")
      end

      assert_equal "Password reset required", result.message
    end

    test "should raise Failed to authenticate when Cognito returns ServiceError" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "valid_password",
            "SECRET_HASH" => Users::AuthService.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Service error"))
        .once

      result = assert_raises(StandardError) do
        AuthService.call(email: @user.email, password: "valid_password")
      end

      assert_equal "Failed to authenticate", result.message
    end

    test "should raise Authentication failed when Cognito returns data but no authentication result" do
      mock_response = mock("CognitoResponse")
      mock_response.stubs(:challenge_name).returns(nil)
      mock_response.stubs(:authentication_result).returns(nil)

      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "valid_password",
            "SECRET_HASH" => Users::AuthService.calculate_secret_hash(@user.email)
          }
        )
        .returns(mock_response)
        .once

      result = assert_raises(StandardError) do
        AuthService.call(email: @user.email, password: "valid_password")
      end

      assert_equal "Authentication failed", result.message
    end

    test "should return a challenge when Cognito returns NEW_PASSWORD_REQUIRED challenge" do
      mock_response = mock("CognitoResponse")
      mock_response.stubs(:challenge_name).returns("NEW_PASSWORD_REQUIRED")
      mock_response.stubs(:session).returns("valid session")

      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "valid_password",
            "SECRET_HASH" => Users::AuthService.calculate_secret_hash(@user.email)
          }
        )
        .returns(mock_response)
        .once

      result = AuthService.call(email: @user.email, password: "valid_password")

      assert_equal "NEW_PASSWORD_REQUIRED", result[:challenge_name]
      assert_equal "valid session", result[:session]
    end

    test "should return authentication tokens when Cognito returns authentication result" do
      mock_response = mock("CognitoResponse")
      mock_response.stubs(:challenge_name).returns(nil)
      mock_authentication_result = mock("AuthenticationResult")
      mock_authentication_result.stubs(:access_token).returns("valid_access_token")
      mock_authentication_result.stubs(:id_token).returns("valid_id_token")
      mock_authentication_result.stubs(:refresh_token).returns("valid_refresh_token")
      mock_response.stubs(:authentication_result).returns(mock_authentication_result)

      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "valid_password",
            "SECRET_HASH" => Users::AuthService.calculate_secret_hash(@user.email)
          }
        )
        .returns(mock_response)
        .once

      result = AuthService.call(email: @user.email, password: "valid_password")

      assert_equal "valid_access_token", result[:access_token]
      assert_equal "valid_id_token", result[:id_token]
      assert_equal "valid_refresh_token", result[:refresh_token]
    end
  end
end
