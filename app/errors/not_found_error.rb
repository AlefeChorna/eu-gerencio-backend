class NotFoundError < ApplicationError
  def initialize(entity: "")
    message = entity ? "#{entity} not found" : "Not found"
    super(
      status: :not_found,
      code: "NotFound",
      message: message
    )
  end
end
