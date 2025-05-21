class AuthError < ApplicationError
  def initialize(code: "AuthError", message: "")
    super(
      status: :bad_request,
      code: code,
      message: message
    )
  end

  def self.login_failed
    new(message: "Failed to authenticate")
  end

  def self.invalid_credentials
    new(message: "Invalid credentials")
  end

  def self.password_reset_required
    new(code: "PasswordResetRequired", message: "Password reset required")
  end
end
