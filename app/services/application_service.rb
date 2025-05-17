class ApplicationService
  Response = Struct.new(:success?, :payload, :error) do
    def failure?
      !success?
    end
  end

  def initialize(propagate = true)
    @propagate = propagate
  end

  def self.call(...)
    service = new(false)
    service.call(...)
  rescue StandardError => e
    service.failure(e)
  end

  def self.call!(...)
    new(true).call(...)
  end

  def success(payload = nil)
    Response.new(true, payload)
  end

  def failure(exception, options = {})
    raise exception if @propagate

    Rails.logger.error("Service error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    ActiveSupport::Notifications.instrument("service.failure",
      service: self.class.name,
      error: exception,
      options: options
    )

    Response.new(false, nil, exception)
  end
end
