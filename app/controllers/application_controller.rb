class ApplicationController < ActionController::API
  include ErrorHandler

  before_action :set_default_format

  private

  def set_default_format
    request.format = :json unless params[:format]
  end

  def current_user
    @current_user ||= request.env[:current_user]
  end

  def authenticate_user!
    render json: { error: "Not Authorized" }, status: :unauthorized unless current_user
  end
end
