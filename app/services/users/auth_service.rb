class Users::AuthService < ApplicationService
  def self.call(email:, password:)
    user = User.find_by(email: email)
    if not user
      Rails.logger.error("User #{email} not found")
      raise AuthError.invalid_credentials
    end

    begin
      auth_params = {
        "USERNAME" => email,
        "PASSWORD" => password,
        "SECRET_HASH" => AuthHelper.calculate_secret_hash(email)
      }

      response = AWS[:cognito].admin_initiate_auth(
        user_pool_id: ENV["COGNITO_USER_POOL_ID"],
        client_id: ENV["COGNITO_CLIENT_ID"],
        auth_flow: "ADMIN_NO_SRP_AUTH",
        auth_parameters: auth_params
      )

      if response.challenge_name == "NEW_PASSWORD_REQUIRED"
        return {
          challenge_name: response.challenge_name,
          session: response.session
        }
      end

      if response.authentication_result
        return {
          access_token: response.authentication_result.access_token,
          id_token: response.authentication_result.id_token,
          refresh_token: response.authentication_result.refresh_token
        }
      end

      Rails.logger.error("Authentication failed #{response}")
      raise AuthError.login_failed
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
      raise AuthError.invalid_credentials
    rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      Rails.logger.error("Cognito: User #{email} not found")
      raise AuthError.invalid_credentials
    rescue Aws::CognitoIdentityProvider::Errors::PasswordResetRequiredException
      raise AuthError.password_reset_required
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Unmapped Cognito error: #{e.backtrace.join("\n")}")
      raise AuthError.login_failed
    end
  end
end
