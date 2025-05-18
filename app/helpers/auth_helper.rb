require "base64"
require "openssl"

class AuthHelper
  def self.calculate_secret_hash(username)
    digest = OpenSSL::Digest.new("sha256")
    hmac = OpenSSL::HMAC.digest(digest, ENV["COGNITO_CLIENT_SECRET"], "#{username}#{ENV["COGNITO_CLIENT_ID"]}")
    Base64.strict_encode64(hmac)
  end
end
