require "test_helper"

module Users
  class CreateUserServiceTest < ActiveSupport::TestCase
    setup do
      @company = Company.create!(
        trader_name: "Test Company",
        entity_attributes: {
          registration_number: "12345678901234",
          registration_type: "cnpj"
        }
      )

      @user_params = {
        email: "test@example.com",
        first_name: "Test",
        last_name: "User",
        company_id: @company.id
      }

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should not save user if validation fails" do
      @user_params[:email] = "invalid_email"
      result = CreateUserService.call(@user_params)
      assert_equal [ "is invalid" ], result[:email]
    end

    test "should rollback transaction on cognito error" do
      AWS[:cognito].expects(:admin_get_user)
        .with(user_pool_id: ENV["COGNITO_USER_POOL_ID"], username: @user_params[:email])
        .raises(StandardError.new("Cognito error"))
        .once
      AWS[:cognito].expects(:admin_create_user).never

      assert_raises StandardError do
        CreateUserService.call(@user_params)
      end

      assert_nil User.find_by(email: @user_params[:email])
    end

    test "should not create user if user already exists in cognito" do
      AWS[:cognito].expects(:admin_get_user)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          username: @user_params[:email]
        )
        .once
      AWS[:cognito].expects(:admin_create_user).never
      Rails.logger.expects(:info).with("User with email #{@user_params[:email]} already exists in Cognito - skipping creation")

      CreateUserService.call(@user_params)

      assert User.find_by(email: @user_params[:email])
    end

    test "should create user when valid params" do
      AWS[:cognito].expects(:admin_get_user)
        .with(user_pool_id: ENV["COGNITO_USER_POOL_ID"], username: @user_params[:email])
        .raises(Aws::CognitoIdentityProvider::Errors::UserNotFoundException.new(nil, "User does not exist"))
        .once
      AWS[:cognito].expects(:admin_create_user)
        .with(
          user_pool_id: ENV['COGNITO_USER_POOL_ID'],
          username: @user_params[:email],
          user_attributes: [
            { name: "email", value: @user_params[:email] },
            { name: "given_name", value: @user_params[:first_name] },
            { name: "family_name", value: @user_params[:last_name] }
          ]
        )
        .once

      result = CreateUserService.call(@user_params)
      db_user = User.find_by(email: @user_params[:email])
      assert result
      assert_equal db_user.email, result.email
      assert_equal db_user.first_name, result.first_name
      assert_equal db_user.last_name, result.last_name
      assert_equal db_user.company_id, result.company_id
    end
  end
end
