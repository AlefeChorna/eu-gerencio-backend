class Authentication
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    return @app.call(env) if skip_authentication?(request.path)
    token = extract_token(request)
    unless token
      return [ 401, { "Content-Type" => "application/json" }, [ AuthError.token_not_found.to_json ] ]
    end
    begin
      decoded_token = JsonWebToken.verify(token)
      payload = decoded_token[0]
      user = User.find_by(email: payload["email"])
      unless user
        return [ 404, { "Content-Type" => "application/json" }, [ NotFoundError.user.to_json ] ]
      end
      env[:current_user] = user
      @app.call(env)
    rescue JWT::VerificationError, JWT::DecodeError => e
      [ 401, { "Content-Type" => "application/json" }, [ AuthError.token_expired.to_json ] ]
    end
  end

  private

  def skip_authentication?(path)
    return true if path.start_with?("/rails/")
    return true if path.start_with?("/auth/")
    false
  end

  def extract_token(request)
    request.get_header("HTTP_AUTHORIZATION")&.split(" ")&.last
  end
end
