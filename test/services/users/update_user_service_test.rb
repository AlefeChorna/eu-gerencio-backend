require "test_helper"

module Users
  class UpdateUserServiceTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)

      AWS[:cognito] = mock("Aws::CognitoIdentityProvider::Client")
    end

    test "should raise an error when trying to update email" do
      error = assert_raises ArgumentError do
        UpdateUserService.call(@user.id, { email: "new@example.com" })
      end
      assert_equal "Email cannot be updated", error.message
    end

    test "should raise an error when trying to update company_id" do
      error = assert_raises ArgumentError do
        UpdateUserService.call(@user.id, { company_id: "new@example.com" })
      end
      assert_equal "Company ID cannot be updated", error.message
    end

    test "should not update user if validation fails" do
      result = UpdateUserService.call(@user.id, { first_name: "" })
      assert_equal [ "can't be blank" ], result[:first_name]
    end

    test "should rollback transaction on cognito error" do
      AWS[:cognito].expects(:admin_update_user_attributes)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          username: @user.email,
          user_attributes: [
            { name: "given_name", value: "New Name" },
            { name: "family_name", value: "Doe" }
          ]
        )
        .raises(StandardError.new("Cognito error"))
        .once

      result = assert_raises StandardError do
        UpdateUserService.call(@user.id, { first_name: "New Name" })
      end

      user = User.find(@user.id)
      assert_equal "John", user.first_name
      assert_equal "Doe", user.last_name
      assert_equal "Failed to update user", result.message
    end

    test "should update user when valid params" do
      AWS[:cognito].expects(:admin_update_user_attributes)
        .with(
          user_pool_id: ENV["COGNITO_USER_POOL_ID"],
          username: @user.email,
          user_attributes: [
            { name: "given_name", value: "New First" },
            { name: "family_name", value: "New Last" }
          ]
        )
        .once

      result = UpdateUserService.call(@user.id, {
        first_name: "New First",
        last_name: "New Last"
      })
      db_user = User.find(@user.id)

      assert result
      assert_equal result.first_name, db_user.first_name
      assert_equal result.last_name, db_user.last_name
    end
  end
end
