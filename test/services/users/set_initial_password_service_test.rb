require "test_helper"

module Users
  class SetInitialPasswordServiceTest < ActiveSupport::TestCase
    setup do
      @company = Company.create!(
        trader_name: "Test Company",
        entity_attributes: {
          registration_number: "12345678901234",
          registration_type: "cnpj"
        }
      )

      @user = User.create!(
        email: "test@example.com",
        first_name: "Test",
        last_name: "User",
        company_id: @company.id
      )

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should raise a user not found error when does not exist in the database" do
      error = assert_raises ActiveRecord::RecordNotFound do
        SetInitialPasswordService.call(
          session: "test-session",
          email: "nonexistent@example.com",
          new_password: "new_password123"
        )
      end
      assert_equal "User not found", error.message
    end

    test "should raise the received error when Cognito returns NotAuthorizedException" do
      AWS[:cognito].expects(:admin_respond_to_auth_challenge)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          challenge_name: "NEW_PASSWORD_REQUIRED",
          challenge_responses: {
            "USERNAME" => @user.email,
            "NEW_PASSWORD" => "new_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          },
          session: "invalid session"
        )
        .raises(Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, "User session expired"))
        .once

      result = assert_raises(StandardError) do
        SetInitialPasswordService.call(
          session: "invalid session",
          email: @user.email,
          new_password: "new_password"
        )
      end

      assert_equal "User session expired", result.message
    end

    test "should raise Invalid password error when Cognito returns InvalidPasswordException" do
      AWS[:cognito].expects(:admin_respond_to_auth_challenge)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          challenge_name: "NEW_PASSWORD_REQUIRED",
          challenge_responses: {
            "USERNAME" => @user.email,
            "NEW_PASSWORD" => "too_short",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          },
          session: "valid session"
        )
        .raises(Aws::CognitoIdentityProvider::Errors::InvalidPasswordException.new(nil, "Password does not conform to policy: Password must have uppercase characters"))
        .once

      result = assert_raises(StandardError) do
        SetInitialPasswordService.call(
          session: "valid session",
          email: @user.email,
          new_password: "too_short"
        )
      end

      assert_equal "Password does not conform to policy: Password must have uppercase characters", result.message
    end

    test "should raise Failed to set new password when Cognito returns ServiceError" do
      AWS[:cognito].expects(:admin_respond_to_auth_challenge)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          challenge_name: "NEW_PASSWORD_REQUIRED",
          challenge_responses: {
            "USERNAME" => @user.email,
            "NEW_PASSWORD" => "new_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          },
          session: "invalid session"
        )
        .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Service error"))
        .once

      result = assert_raises(StandardError) do
        SetInitialPasswordService.call(
          session: "invalid session",
          email: @user.email,
          new_password: "new_password"
        )
      end

      assert_equal "Failed to set new password", result.message
    end

    test "should raise Set new password failed when Cognito returns data but no authentication result" do
      mock_response = mock("CognitoResponse")
      mock_response.stubs(:challenge_name).returns(nil)
      mock_response.stubs(:authentication_result).returns(nil)

      AWS[:cognito].expects(:admin_respond_to_auth_challenge)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          challenge_name: "NEW_PASSWORD_REQUIRED",
          challenge_responses: {
            "USERNAME" => @user.email,
            "NEW_PASSWORD" => "new_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          },
          session: "valid session"
        )
        .returns(mock_response)
        .once

      result = assert_raises(StandardError) do
        SetInitialPasswordService.call(
          session: "valid session",
          email: @user.email,
          new_password: "new_password"
        )
      end

      assert_equal "Set new password failed", result.message
    end

    test "should return authentication tokens when Cognito returns authentication result" do
      mock_response = mock("CognitoResponse")
      mock_response.stubs(:challenge_name).returns(nil)
      mock_authentication_result = mock("AuthenticationResult")
      mock_authentication_result.stubs(:access_token).returns("valid_access_token")
      mock_authentication_result.stubs(:id_token).returns("valid_id_token")
      mock_authentication_result.stubs(:refresh_token).returns("valid_refresh_token")
      mock_response.stubs(:authentication_result).returns(mock_authentication_result)

      AWS[:cognito].expects(:admin_respond_to_auth_challenge)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          client_id: ENV["COGNITO_CLIENT_ID"],
          challenge_name: "NEW_PASSWORD_REQUIRED",
          challenge_responses: {
            "USERNAME" => @user.email,
            "NEW_PASSWORD" => "new_password",
            "SECRET_HASH" => AuthHelper.calculate_secret_hash(@user.email)
          },
          session: "valid session"
        )
        .returns(mock_response)
        .once

      result = SetInitialPasswordService.call(
        session: "valid session",
        email: @user.email,
        new_password: "new_password"
      )

      assert_equal "valid_access_token", result[:access_token]
      assert_equal "valid_id_token", result[:id_token]
      assert_equal "valid_refresh_token", result[:refresh_token]
    end
  end
end
