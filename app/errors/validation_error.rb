class ValidationError < ApplicationError
  attr_reader :errors

  def initialize(errors: {}, message: "Validation failed")
    @errors = errors
    super(
      status: :unprocessable_entity,
      code: "ValidationError",
      message: message,
      details: errors
    )
  end
end
