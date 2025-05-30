class AuthController < ApplicationController
  def login
    result = Users::AuthService.call(email: params[:email], password: params[:password])
    render json: result, status: :ok
  end

  def set_initial_password
    result = Users::SetInitialPasswordService.call(
      session: params[:session],
      email: params[:email],
      new_password: params[:new_password]
    )
    render json: result, status: :ok
  end

  def forgot_password
    result = Users::InitiatePasswordResetService.call(email: params[:email])
    render json: result, status: :ok
  end

  def resend_verification_code
    result = Users::InitiatePasswordResetService.call(email: params[:email])
    render json: result, status: :ok
  end

  def reset_password
    Users::ResetPasswordService.call(
      email: params[:email],
      confirmation_code: params[:confirmation_code],
      new_password: params[:new_password]
    )
    head :no_content
  end
end
