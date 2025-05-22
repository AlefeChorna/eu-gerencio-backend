require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:user_one)
    AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
  end

  test "[POST /auth/login] should return an error with invalid credentials" do
    AWS[:cognito]
      .expects(:admin_initiate_auth)
      .raises(Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, "Incorrect username or password"))

    post auth_login_url, params: { email: @user.email, password: "wrong_password" }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal(
      {
        "status" => 400,
        "code" => "AuthError",
        "message" => "Invalid credentials"
      },
      json_response
    )
  end

  test "[POST /auth/login] should return auth tokens with valid credentials" do
    auth_response = {
      access_token: "test_access_token",
      id_token: "test_id_token",
      refresh_token: "test_refresh_token"
    }

    mock_response = mock("CognitoResponse")
    mock_response.stubs(:challenge_name).returns(nil)
    mock_authentication_result = mock("AuthenticationResult")
    mock_authentication_result.stubs(:access_token).returns(auth_response[:access_token])
    mock_authentication_result.stubs(:id_token).returns(auth_response[:id_token])
    mock_authentication_result.stubs(:refresh_token).returns(auth_response[:refresh_token])
    mock_response.stubs(:authentication_result).returns(mock_authentication_result)

    AWS[:cognito].expects(:admin_initiate_auth).returns(mock_response)

    post auth_login_url, params: { email: @user.email, password: "valid-password" }, as: :json

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal auth_response[:id_token], json_response["id_token"]
    assert_equal auth_response[:access_token], json_response["access_token"]
    assert_equal auth_response[:refresh_token], json_response["refresh_token"]
  end

  test "[POST /auth/set-initial-password] should return error for invalid session" do
    AWS[:cognito]
      .expects(:admin_respond_to_auth_challenge)
      .raises(Aws::CognitoIdentityProvider::Errors::NotAuthorizedException.new(nil, "session is expired"))

    post auth_set_initial_password_url, params: {
      session: "invalid_session",
      email: @user.email,
      new_password: "NewPassword123!"
    }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal(
      {
        "status" => 400,
        "code" => "SessionExpired",
        "message" => "Session expired"
      },
      json_response
    )
  end

  test "[POST /auth/set-initial-password] should set initial password successfully" do
    mock_response = mock("CognitoResponse")
    mock_auth_result = mock("AuthenticationResult")
    auth_response = {
      access_token: "new_access_token",
      id_token: "new_id_token",
      refresh_token: "new_refresh_token"
    }

    mock_auth_result.stubs(:access_token).returns(auth_response[:access_token])
    mock_auth_result.stubs(:id_token).returns(auth_response[:id_token])
    mock_auth_result.stubs(:refresh_token).returns(auth_response[:refresh_token])
    mock_response.stubs(:authentication_result).returns(mock_auth_result)

    AWS[:cognito].expects(:admin_respond_to_auth_challenge).returns(mock_response)

    post auth_set_initial_password_url, params: {
      session: "test_session",
      email: @user.email,
      new_password: "NewPassword123!"
    }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal auth_response[:id_token], json_response["id_token"]
    assert_equal auth_response[:access_token], json_response["access_token"]
    assert_equal auth_response[:refresh_token], json_response["refresh_token"]
  end

  test "[POST /auth/forgot-password] should return error if something goes wrong" do
    AWS[:cognito].expects(:forgot_password)
      .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Something went wrong"))

    post auth_forgot_password_url, params: { email: @user.email }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal(
      {
        "status" => 400,
        "code" => "AuthError",
        "message" => "Password reset failed"
      },
      json_response
    )
  end

  test "[POST /auth/forgot-password] should initiate password reset successfully" do
    mock_response = mock("CognitoResponse")
    mock_code_delivery = mock("CodeDeliveryDetails")
    code_delivery_response = {
      delivery_medium: "EMAIL",
      destination: "e***@e***"
    }

    mock_code_delivery.stubs(:delivery_medium).returns(code_delivery_response[:delivery_medium])
    mock_code_delivery.stubs(:destination).returns(code_delivery_response[:destination])
    mock_response.stubs(:code_delivery_details).returns(mock_code_delivery)

    AWS[:cognito].expects(:forgot_password).returns(mock_response)

    post auth_forgot_password_url, params: { email: @user.email }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal code_delivery_response[:delivery_medium], json_response["delivery_medium"]
    assert_equal code_delivery_response[:destination], json_response["delivery_destination"]
  end

  test "[POST /auth/resend-verification-code] should return error if something goes wrong" do
    AWS[:cognito]
      .expects(:resend_confirmation_code)
      .raises(Aws::CognitoIdentityProvider::Errors::ServiceError.new(nil, "Something went wrong"))

    post auth_resend_verification_code_url, params: { email: @user.email }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "Failed to resend verification code", json_response["error"]
  end

  test "[POST /auth/resend-verification-code] should resend verification code successfully" do
    mock_response = mock("CognitoResponse")
    mock_code_delivery = mock("CodeDeliveryDetails")
    code_delivery_response = {
      delivery_medium: "EMAIL",
      destination: "e***@e***"
    }

    mock_code_delivery.stubs(:delivery_medium).returns(code_delivery_response[:delivery_medium])
    mock_code_delivery.stubs(:destination).returns(code_delivery_response[:destination])
    mock_response.stubs(:code_delivery_details).returns(mock_code_delivery)

    AWS[:cognito]
      .expects(:resend_confirmation_code)
      .returns(mock_response)

    post auth_resend_verification_code_url, params: { email: @user.email }, as: :json

    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal code_delivery_response[:delivery_medium], json_response["delivery_medium"]
    assert_equal code_delivery_response[:destination], json_response["delivery_destination"]
  end

  test "[POST /auth/reset-password] should return error for invalid confirmation code" do
    AWS[:cognito]
      .expects(:confirm_forgot_password)
      .raises(Aws::CognitoIdentityProvider::Errors::CodeMismatchException.new(nil, "Invalid code"))

    post auth_reset_password_url, params: {
      email: @user.email,
      confirmation_code: "wrong_code",
      new_password: "NewPassword123!"
    }, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal(
      {
        "status" => 400,
        "code" => "InvalidConfirmationCode",
        "message" => "Invalid confirmation code"
      },
      json_response
    )
  end

  test "[POST /auth/reset-password] should reset password successfully" do
    AWS[:cognito].expects(:confirm_forgot_password)

    post auth_reset_password_url, params: {
      email: @user.email,
      confirmation_code: "123456",
      new_password: "NewPassword123!"
    }, as: :json

    assert_response :no_content
  end
end
