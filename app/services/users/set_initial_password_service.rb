class Users::SetInitialPasswordService < ApplicationService
  def self.call(session:, email:, new_password:)
    user = User.find_by(email: email)
    if not user
      Rails.logger.error("User #{email} not found")
      raise AuthError.invalid_credentials
    end

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

      Rails.logger.error("Failed to set initial password #{response}")
      raise AuthError.failed_to_set_new_password
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException => e
      not_authorized_exception(e)
    rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
      raise AuthError.invalid_password(e.message)
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Cognito error: (#{e.message}) #{e.backtrace.join("\n")}")
      raise AuthError.failed_to_set_new_password
    end
  end

  private

  def self.not_authorized_exception(e)
    is_session_expired = e.message.include?("session is expired")
    if is_session_expired
      raise AuthError.session_expired
    end
    raise AuthError.invalid_credentials
  end
end
