class Users::ResendVerificationCodeService < ApplicationService
  def self.call(email:)
    user = User.find_by(email: email)
    raise ActiveRecord::RecordNotFound, "User not found" unless user

    begin
      response = AWS[:cognito].resend_confirmation_code(
        client_id: ENV["COGNITO_CLIENT_ID"],
        username: email,
        secret_hash: AuthHelper.calculate_secret_hash(email)
      )

      {
        delivery_medium: response.code_delivery_details.delivery_medium,
        delivery_destination: response.code_delivery_details.destination
      }
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Cognito error: #{e.backtrace}")
      raise StandardError.new("Failed to resend verification code")
    end
  end
end
