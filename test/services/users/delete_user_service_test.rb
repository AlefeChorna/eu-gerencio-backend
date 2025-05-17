require "test_helper"

module Users
  class DeleteUserServiceTest < ActiveSupport::TestCase
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

    test "should rollback transaction on cognito error" do
      AWS[:cognito].expects(:admin_delete_user)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          username: @user.email
        )
        .raises(StandardError.new("Cognito error"))
        .once

      assert_raises StandardError do
        DeleteUserService.call(@user.id)
      end

      assert User.find_by(id: @user.id)
    end

    test "should raise error when user not found" do
      assert_raises ActiveRecord::RecordNotFound do
        DeleteUserService.call(999999)
      end
    end

    test "should delete user successfully" do
      AWS[:cognito].expects(:admin_delete_user)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          username: @user.email
        )
        .once

      DeleteUserService.call(@user.id)
      assert_nil User.find_by(id: @user.id)
    end
  end
end
