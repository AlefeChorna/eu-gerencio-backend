class InternalServerError < ApplicationError
  def initialize(message: "Internal Server Error", details: nil)
    super(
      status: :internal_server_error,
      code: "InternalServerError",
      message: message,
      details: details
    )
  end
end
