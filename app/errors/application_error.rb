class ApplicationError < StandardError
  attr_reader :status, :code, :message, :details

  def initialize(status: :internal_server_error, code: "InternalServerError", message: "Something went wrong", details: nil)
    @status = status.is_a?(Symbol) ? status : status.to_sym
    @code = code
    @message = message
    @details = details
    super(message)
  end

  def status_code
    Rack::Utils.status_code(status)
  end

  def to_h
    {
      status: status_code,
      code: code,
      message: message,
      details: details
    }.compact
  end

  def to_json(*_args)
    to_h.to_json
  end
end
