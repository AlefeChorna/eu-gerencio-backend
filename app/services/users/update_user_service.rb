class Users::UpdateUserService < ApplicationService
  def self.call(user_id, user_params)
    user = User.find(user_id)

    if user_params.key?(:email)
      raise ArgumentError, "Email cannot be updated"
    end

    if user_params.key?(:company_id)
      raise ArgumentError, "Company ID cannot be updated"
    end

    User.transaction do
      if not user.update(user_params)
        return user.errors
      end

      update_cognito_user(user)
      user
    rescue StandardError => e
      Rails.logger.error("Error updating user: #{e.class.name} - #{e.message}")
      raise e
    end
  end

  private

  def self.update_cognito_user(user)
    AWS[:cognito].admin_update_user_attributes(
      user_pool_id: ENV["COGNITO_USER_POOL_ID"],
      username: user.email,
      user_attributes: [
        {
          name: "given_name",
          value: user.first_name
        },
        {
          name: "family_name",
          value: user.last_name
        }
      ]
    )
  end
end
