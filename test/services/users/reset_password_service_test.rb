require "test_helper"

module Users
  class ResetPasswordServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should raise user not found error when user does not exist in the database" do
      error = assert_raises ActiveRecord::RecordNotFound do
        ResetPasswordService.call(
          email: "nonexistent@example.com",
          confirmation_code: "123456",
          new_password: "new_password123"
        )
      end
      assert_equal "User not found", error.message
    end

    test "should raise Invalid confirmation code error when confirmation code is invalid" do
      AWS[:cognito].expects(:confirm_forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          confirmation_code: "invalid_code",
          password: "new_password",
          secret_hash: AuthHelper.calculate_secret_hash(@user.email)
        )
        .raises(Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new(nil, "Invalid confirmation code"))
        .once

      result = assert_raises(StandardError) do
        ResetPasswordService.call(
          email: @user.email,
          confirmation_code: "invalid_code",
          new_password: "new_password"
        )
      end

      assert_equal "Invalid confirmation code", result.message
    end

    test "should raise Invalid password error when Cognito returns InvalidPasswordException" do
      AWS[:cognito].expects(:confirm_forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          confirmation_code: "123456",
          password: "too_short",
          secret_hash: AuthHelper.calculate_secret_hash(@user.email)
        )
        .raises(Aws::CognitoIdentityProvider::Errors::InvalidPasswordException.new(nil, "Password does not conform to policy: Password must have uppercase characters"))
        .once

      result = assert_raises(StandardError) do
        ResetPasswordService.call(
          email: @user.email,
          confirmation_code: "123456",
          new_password: "too_short"
        )
      end

      assert_equal "Password does not conform to policy: Password must have uppercase characters", result.message
    end

    test "should raise Failed to reset password error when Cognito returns ServiceError" do
      AWS[:cognito].expects(:confirm_forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          confirmation_code: "123456",
          password: "new_password",
          secret_hash: AuthHelper.calculate_secret_hash(@user.email)
        )
        .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Service error"))
        .once

      result = assert_raises(StandardError) do
        ResetPasswordService.call(
          email: @user.email,
          confirmation_code: "123456",
          new_password: "new_password"
        )
      end

      assert_equal "Failed to reset password", result.message
    end

    test "should successfully reset password for existing user" do
      AWS[:cognito].expects(:confirm_forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          confirmation_code: "123456",
          password: "new_password",
          secret_hash: AuthHelper.calculate_secret_hash(@user.email)
        )
        .returns(mock("CognitoResponse"))
        .once

      ResetPasswordService.call(
        email: @user.email,
        confirmation_code: "123456",
        new_password: "new_password"
      )
    end
  end
end
