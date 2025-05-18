require "test_helper"

module Users
  class DeleteUserServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)

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

      result = assert_raises StandardError do
        DeleteUserService.call(@user.id)
      end

      assert User.find_by(id: @user.id)
      assert_equal "Failed to delete user", result.message
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
