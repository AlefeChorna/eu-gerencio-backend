module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # Handle exceptions at the controller level
    around_action :handle_exceptions

    # Keep these for backward compatibility
    rescue_from StandardError, with: :handle_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error
    rescue_from ApplicationError, with: :handle_application_error
  end

  private

  def handle_exceptions
    yield
  rescue => exception
    handle_exception(exception)
  end

  def handle_exception(exception)
    case exception
    when ActiveRecord::RecordNotFound
      handle_not_found(exception)
    when ActiveRecord::RecordInvalid
      handle_validation_error(exception)
    when ApplicationError
      handle_application_error(exception)
    else
      handle_error(exception)
    end
  end

  def handle_not_found(exception)
    error = if exception.try(:model)
              NotFoundError.new(entity: exception.model)
    else
              NotFoundError.new(entity: "Resource")
    end
    render_error(error)
  end

  def handle_validation_error(exception)
    error = ValidationError.new(
      errors: exception.record.errors.messages,
      message: exception.message
    )
    render_error(error)
  end

  def handle_application_error(exception)
    render_error(exception)
  end

  def handle_error(exception)
    Rails.logger.error("Unhandled error: #{exception.class.name}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n")) if exception.backtrace

    error = InternalServerError.new(
      message: "Something went wrong",
      details: Rails.env.development? ? exception.message : nil
    )
    render_error(error, false)
  end

  def render_error(error, log_error = true)
    if log_error
      Rails.logger.error("#{error.class.name}: #{error.message}")
      Rails.logger.error(error.backtrace.join("\n")) if error.backtrace
    end

    self.content_type = "application/json"
    self.response_body = error.to_json
    self.status = error.status

    response.committed? || response.send(:commit!)
  rescue => e
    Rails.logger.error("Error rendering error response: #{e.message}")
    render json: { error: error.message }, status: error.status
  end
end
