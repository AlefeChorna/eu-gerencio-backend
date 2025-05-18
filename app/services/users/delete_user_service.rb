class Users::DeleteUserService < ApplicationService
  def self.call(user_id)
    user = User.find(user_id)

    User.transaction do
      delete_cognito_user(user)
      user.destroy
      nil
    rescue StandardError => e
      Rails.logger.error("Error deleting user: #{e.backtrace}")
      raise StandardError.new("Failed to delete user")
    end
  end

  private

  def self.delete_cognito_user(user)
    AWS[:cognito].admin_delete_user(
      user_pool_id: ENV["COGNITO_USER_POOL_ID"],
      username: user.email
    )
  end
end
