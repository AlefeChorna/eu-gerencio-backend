require "test_helper"

module Users
  class ResetPasswordServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should raise AuthError (Password reset failed) when user does not exist in the database" do
      email = "nonexistent@example.com"

      assert_nil User.find_by(email: email)
      Rails.logger.expects(:error).with("User #{email} not found")

      error = assert_raises AuthError do
        ResetPasswordService.call(
          email: email,
          confirmation_code: "123456",
          new_password: "new_password123"
        )
      end
      assert_equal "Password reset failed", error.message
    end

    test "should raise AuthError (Invalid confirmation code) when confirmation code is invalid" do
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

      result = assert_raises(AuthError) do
        ResetPasswordService.call(
          email: @user.email,
          confirmation_code: "invalid_code",
          new_password: "new_password"
        )
      end

      assert_equal "Invalid confirmation code", result.message
    end

    test "should raise AuthError (Confirmation code expired) when confirmation code is expired" do
      AWS[:cognito].expects(:confirm_forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          confirmation_code: "invalid_code",
          password: "new_password",
          secret_hash: AuthHelper.calculate_secret_hash(@user.email)
        )
        .raises(Aws::CognitoIdentityProvider::Errors::ExpiredCodeException.new(nil, "Expired confirmation code"))
        .once

      result = assert_raises(AuthError) do
        ResetPasswordService.call(
          email: @user.email,
          confirmation_code: "invalid_code",
          new_password: "new_password"
        )
      end

      assert_equal "Confirmation code expired", result.message
    end

    test "should raise AuthError (Invalid password format) when Cognito returns InvalidPasswordException" do
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

      result = assert_raises(AuthError) do
        ResetPasswordService.call(
          email: @user.email,
          confirmation_code: "123456",
          new_password: "too_short"
        )
      end

      assert_equal "Password does not conform to policy: Password must have uppercase characters", result.message
    end

    test "should raise AuthError (Password reset failed) when Cognito returns ServiceError" do
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

      Rails.logger.expects(:error).once

      result = assert_raises(AuthError) do
        ResetPasswordService.call(
          email: @user.email,
          confirmation_code: "123456",
          new_password: "new_password"
        )
      end

      assert_equal "Password reset failed", result.message
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
