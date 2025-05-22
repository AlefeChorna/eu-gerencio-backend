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

  def self.invalid_password(message)
    new(code: "InvalidPassword", message: message)
  end

  def self.session_expired
    new(code: "SessionExpired", message: "Session expired")
  end

  def self.failed_to_set_new_password
    new(message: "Failed to set new password")
  end

  def self.password_reset_failed
    new(message: "Password reset failed")
  end
end
