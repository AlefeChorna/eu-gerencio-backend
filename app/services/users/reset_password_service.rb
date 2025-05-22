class Users::ResetPasswordService < ApplicationService
  def self.call(email:, confirmation_code:, new_password:)
    user = User.find_by(email: email)
    if not user
      Rails.logger.error("User #{email} not found")
      raise AuthError.password_reset_failed
    end

    begin
      AWS[:cognito].confirm_forgot_password(
        client_id: ENV["COGNITO_CLIENT_ID"],
        username: email,
        confirmation_code: confirmation_code,
        password: new_password,
        secret_hash: AuthHelper.calculate_secret_hash(email)
      )
    rescue Aws::CognitoIdentityProvider::Errors::CodeMismatchException
      raise AuthError.invalid_confirmation_code
    rescue Aws::CognitoIdentityProvider::Errors::ExpiredCodeException
      raise AuthError.confirmation_code_expired
    rescue Aws::CognitoIdentityProvider::Errors::InvalidPasswordException => e
      raise AuthError.invalid_password(e.message)
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Cognito error: (#{e.message}) #{e.backtrace}")
      raise AuthError.password_reset_failed
    end
  end
end
