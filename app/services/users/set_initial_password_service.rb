class Users::SetInitialPasswordService < ApplicationService
  def self.call(session:, email:, new_password:)
    user = User.find_by(email: email)
    raise ActiveRecord::RecordNotFound.new("User not found") unless user

    begin
      auth_params = {
        "USERNAME" => email,
        "NEW_PASSWORD" => new_password,
        "SECRET_HASH" => AuthHelper.calculate_secret_hash(email)
      }

      response = AWS[:cognito].admin_respond_to_auth_challenge(
        user_pool_id: ENV["COGNITO_USER_POOL_ID"],
        client_id: ENV["COGNITO_CLIENT_ID"],
        challenge_name: "NEW_PASSWORD_REQUIRED",
        challenge_responses: auth_params,
        session: session
      )

      if response.authentication_result
        return {
          access_token: response.authentication_result.access_token,
          id_token: response.authentication_result.id_token,
          refresh_token: response.authentication_result.refresh_token
        }
      end
      raise StandardError.new("Set new password failed")
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException => e
      raise StandardError.new(e.message)
    rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
      raise StandardError.new(e.message)
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Cognito error: #{e.backtrace}")
      raise StandardError.new("Failed to set new password")
    end
  end
end
