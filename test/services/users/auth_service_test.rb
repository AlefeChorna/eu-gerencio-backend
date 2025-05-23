require "test_helper"

module Users
  class AuthServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should raise AuthError (Invalid credentials) when user does not exist in the database" do
      email = "nonexistent@example.com"
      password = "password123"

      assert_nil User.find_by(email: email)
      Rails.logger.expects(:error).with("User #{email} not found")

      result = assert_raises(AuthError) do
        AuthService.call(email: email, password: password)
      end

      assert_equal "Invalid credentials", result.message
    end

    test "should raise AuthError (Invalid credentials) when Cognito returns NotAuthorizedException" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "wrong_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, "Invalid credentials"))
        .once

      result = assert_raises(AuthError) do
        AuthService.call(email: @user.email, password: "wrong_password")
      end

      assert_equal "Invalid credentials", result.message
    end

    test "should raise AuthError (Invalid credentials) when Cognito returns UserNotFoundException" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "wrong_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new(nil, "User not found"))
        .once

      Rails.logger.expects(:error).with("Cognito: User #{@user.email} not found")

      result = assert_raises(AuthError) do
        AuthService.call(email: @user.email, password: "wrong_password")
      end

      assert_equal "Invalid credentials", result.message
    end

    test "should raise AuthError (Password reset required) when Cognito returns PasswordResetRequiredException" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "wrong_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::PasswordResetRequiredException.new(nil, "Password reset required"))
        .once

      result = assert_raises(AuthError) do
        AuthService.call(email: @user.email, password: "wrong_password")
      end

      assert_equal "Password reset required", result.message
    end

    test "should raise AuthError (Failed to authenticate) when Cognito returns ServiceError" do
      AWS[:cognito].expects(:admin_initiate_auth)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          auth_flow: "ADMIN_NO_SRP_AUTH",
          auth_parameters: {
            "USERNAME" => @user.email,
            "PASSWORD" => "valid_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          }
        )
        .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Service error"))
        .once

      Rails.logger.expects(:error).once

      result = assert_raises(AuthError) do
        AuthService.call(email: @user.email, password: "valid_password")
      end

      assert_equal "Failed to authenticate", result.message
    end

    test "should raise AuthError (Authentication failed) when Cognito returns data but no authentication result" do
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
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          }
        )
        .returns(mock_response)
        .once

      Rails.logger.expects(:error).with("Authentication failed #{mock_response}")

      result = assert_raises(AuthError) do
        AuthService.call(email: @user.email, password: "valid_password")
      end

      assert_equal "Failed to authenticate", result.message
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
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
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
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
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
