require "base64"
require "openssl"

class Users::ResetPasswordService < ApplicationService
  def self.call(email:, confirmation_code:, new_password:)
    user = User.find_by(email: email)
    raise ActiveRecord::RecordNotFound, "User not found" unless user

    begin
      AWS[:cognito].confirm_forgot_password(
        client_id: ENV["COGNITO_CLIENT_ID"],
        username: email,
        confirmation_code: confirmation_code,
        password: new_password,
        secret_hash: calculate_secret_hash(email)
      )
    rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException => e
      raise StandardError.new("Invalid confirmation code")
    rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
      raise StandardError.new("Invalid password")
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Cognito error: #{e.backtrace}")
      raise StandardError.new("Failed to reset password")
    end
  end

  private

  def self.calculate_secret_hash(username)
    digest = OpenSSL::Digest.new("sha256")
    hmac = OpenSSL::HMAC.digest(digest, ENV["COGNITO_CLIENT_SECRET"], "#{username}#{ENV["COGNITO_CLIENT_ID"]}")
    Base64.strict_encode64(hmac)
  end
end
