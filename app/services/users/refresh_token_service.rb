class Users::RefreshTokenService < ApplicationService
  def self.call(expired_token:, refresh_token:)
    begin
      token = JWT.decode(expired_token, nil, false).at(0)
      auth_params = {
        "REFRESH_TOKEN" => refresh_token,
        "SECRET_HASH" => AuthHelper.calculate_secret_hash(token["cognito:username"])
      }
      response = AWS[:cognito].initiate_auth(
        client_id: ENV["COGNITO_CLIENT_ID"],
        auth_flow: "REFRESH_TOKEN_AUTH",
        auth_parameters: auth_params
      )
      if response.authentication_result
        {
          access_token: response.authentication_result.access_token,
          id_token: response.authentication_result.id_token,
          expires_in: response.authentication_result.expires_in
        }
      else
        Rails.logger.error("Token refresh failed: #{response}")
        raise AuthError.token_refresh_failed
      end
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException,
           Aws::CognitoIdentityProvider::Errors::UserNotFoundException => e
      Rails.logger.error("Token refresh failed: (#{e.message}) #{e.backtrace.join("\n")}")
      raise AuthError.invalid_refresh_token
    rescue StandardError => e
      Rails.logger.error("Unexpected error during token refresh: (#{e.message}) #{e.backtrace.join("\n")}")
      raise AuthError.token_refresh_failed
    end
  end
end
