class ApplicationController < ActionController::API
  include ErrorHandler

  before_action :set_default_format

  private

  def set_default_format
    request.format = :json unless params[:format]
  end
end
