require "test_helper"

module Users
  class InitiatePasswordResetServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should raise AuthError (Password reset failed) when user does not exist in the database" do
      email = "nonexistent@example.com"

      assert_nil User.find_by(email: email)
      Rails.logger.expects(:error).with("User #{email} not found")

      error = assert_raises AuthError do
        InitiatePasswordResetService.call(email: email)
      end
      assert_equal "Password reset failed", error.message
    end

    test "should raise AuthError (Password reset failed) when Cognito returns ServiceError" do
      AWS[:cognito].expects(:forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          secret_hash: AuthHelper.calculate_secret_hash(@user.email)
        )
        .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Service error"))
        .once

      Rails.logger.expects(:error).once

      result = assert_raises(AuthError) do
        InitiatePasswordResetService.call(email: @user.email)
      end

      assert_equal "Password reset failed", result.message
    end

    test "should successfully initiate password reset for existing user" do
      mock_response = mock("CognitoResponse")
      mock_code_delivery_details = mock("CodeDeliveryDetails")
      mock_code_delivery_details.stubs(:delivery_medium).returns("EMAIL")
      mock_code_delivery_details.stubs(:destination).returns("te**@**.com")
      mock_response.stubs(:code_delivery_details).returns(mock_code_delivery_details)

      AWS[:cognito].expects(:forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          secret_hash: AuthHelper.calculate_secret_hash(@user.email)
        )
        .returns(mock_response)
        .once

      result = InitiatePasswordResetService.call(email: @user.email)
      assert_equal "EMAIL", result[:delivery_medium]
      assert_equal "te**@**.com", result[:delivery_destination]
    end
  end
end
