require "test_helper"

module Users
  class ResetPasswordServiceTest < ActiveSupport::TestCase
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

    test "should raise user not found error when user does not exist in the database" do
      error = assert_raises ActiveRecord::RecordNotFound do
        ResetPasswordService.call(email: "nonexistent@example.com")
      end
      assert_equal "User with email nonexistent@example.com not found", error.message
    end

    test "should raise Failed to initiate password reset error when Cognito returns ServiceError" do
      AWS[:cognito].expects(:forgot_password)
        .with(
          client_id: ENV["COGNITO_CLIENT_ID"],
          username: @user.email,
          secret_hash: ResetPasswordService.calculate_secret_hash(@user.email)
        )
        .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Service error"))
        .once

      result = assert_raises(StandardError) do
        ResetPasswordService.call(email: @user.email)
      end

      assert_equal "Failed to initiate password reset", result.message
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
          secret_hash: ResetPasswordService.calculate_secret_hash(@user.email)
        )
        .returns(mock_response)
        .once

      result = ResetPasswordService.call(email: @user.email)
      assert_equal "EMAIL", result[:delivery_medium]
      assert_equal "te**@**.com", result[:delivery_destination]
    end
  end
end
