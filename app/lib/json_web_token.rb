require "net/http"
require "json"
require "jwt"

class JsonWebToken
  def self.verify(token)
    decoded_token = JWT.decode(token, nil, false)
    payload = decoded_token.first
    if payload["exp"] && Time.at(payload["exp"]) < Time.current
      raise JWT::ExpiredSignature, "Token has expired"
    end
    if payload["iat"] && Time.at(payload["iat"]) > (Time.current + 30.seconds)
      raise JWT::InvalidIatError, "Invalid token: issued at (iat) is in the future"
    end
    JWT.decode(
      token,
      nil,
      true,
      algorithm: "RS256",
      iss: "https://cognito-idp.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{ENV.fetch('COGNITO_USER_POOL_ID')}",
      verify_iss: true,
      client_id: ENV.fetch("COGNITO_CLIENT_ID"),
      verify_aud: true
    ) do |header|
      jwks_hash[header["kid"]]
    end
  rescue JWT::ExpiredSignature => e
    Rails.logger.error "JWT Token expired: #{e.message}"
    raise
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT Decode error: #{e.message}"
    raise
  end

  def self.jwks_hash
    Rails.cache.fetch("cognito_jwks", expires_in: 1.hour) do
      jwks_uri = URI("https://cognito-idp.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{ENV.fetch('COGNITO_USER_POOL_ID')}/.well-known/jwks.json")
      response = Net::HTTP.get(jwks_uri)
      jwks_keys = JSON.parse(response)["keys"]
      jwks_keys.each_with_object({}) do |key, hash|
        hash[key["kid"]] = JWT::JWK.import(key).public_key
      end
    end
  end
end
