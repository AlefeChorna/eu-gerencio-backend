require "base64"
require "openssl"

class Users::AuthService < ApplicationService
  def self.call(email:, password:)
    user = User.find_by(email: email)
    raise ActiveRecord::RecordNotFound.new("User not found") unless user

    begin
      auth_params = {
        "USERNAME" => email,
        "PASSWORD" => password,
        "SECRET_HASH" => calculate_secret_hash(email)
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
      raise StandardError.new("Authentication failed")
    rescue Aws::CognitoIdentityProvider::Errors::NotAuthorizedException
      raise StandardError.new("Invalid credentials")
    rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      raise ActiveRecord::RecordNotFound.new("SCIM: User not found")
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Cognito error: #{e.backtrace}")
      raise StandardError.new("Failed to authenticate")
    end
  end

  def self.calculate_secret_hash(username)
    digest = OpenSSL::Digest.new("sha256")
    hmac = OpenSSL::HMAC.digest(digest, ENV["COGNITO_CLIENT_SECRET"], "#{username}#{ENV["COGNITO_CLIENT_ID"]}")
    Base64.strict_encode64(hmac)
  end
end
