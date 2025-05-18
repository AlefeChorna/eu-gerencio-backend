class Users::InitiatePasswordResetService
  def self.call(email:)
    user = User.find_by(email: email)
    raise ActiveRecord::RecordNotFound, "User not found" unless user

    begin
      response = AWS[:cognito].forgot_password(
        client_id: ENV["COGNITO_CLIENT_ID"],
        username: email,
        secret_hash: calculate_secret_hash(email)
      )

      {
        delivery_medium: response.code_delivery_details.delivery_medium,
        delivery_destination: response.code_delivery_details.destination
      }
    rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
      Rails.logger.error("Cognito error: #{e.backtrace}")
      raise StandardError.new("Failed to initiate password reset")
    end
  end

  private

  def self.calculate_secret_hash(username)
    digest = OpenSSL::Digest.new("sha256")
    hmac = OpenSSL::HMAC.digest(digest, ENV["COGNITO_CLIENT_SECRET"], "#{username}#{ENV["COGNITO_CLIENT_ID"]}")
    Base64.strict_encode64(hmac)
  end
end
