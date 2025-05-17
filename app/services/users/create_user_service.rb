class Users::CreateUserService < ApplicationService
  def self.call(user_params)
    user = User.new(user_params)
    
    User.transaction do
      if not user.save
        return user.errors
      end
      
      create_cognito_user(user)
      user
    rescue StandardError => e
      Rails.logger.error("Error creating user: #{e.class.name} - #{e.message}")
      raise e
    end
  end

  private

  def self.user_exists_in_cognito?(email)
    AWS[:cognito].admin_get_user(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: email
    )
    true
  rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException => e
    false
  end

  def self.create_cognito_user(user)
    if user_exists_in_cognito?(user.email)
      Rails.logger.info("User with email #{user.email} already exists in Cognito - skipping creation")
      return
    end

    AWS[:cognito].admin_create_user(
      user_pool_id: ENV['COGNITO_USER_POOL_ID'],
      username: user.email,
      user_attributes: [
        {
          name: 'email',
          value: user.email
        },
        {
          name: 'given_name',
          value: user.first_name
        },
        {
          name: 'family_name',
          value: user.last_name
        }
      ]
    )
  end
end
