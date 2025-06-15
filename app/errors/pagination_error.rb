# app/errors/pagination_error.rb
class PaginationError < ApplicationError
  def initialize(message: "")
    super(
      status: :unprocessable_entity,
      code: "PaginationError",
      message: message
    )
  end

  def self.max_per_page_exceeded(max_per_page)
    new(message: "per_page cannot exceed #{max_per_page}")
  end

  def self.invalid_page
    new(message: "page cannot be less than 1")
  end
end
