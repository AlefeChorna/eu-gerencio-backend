class ApplicationController < ActionController::API
  include ErrorHandler
  include Pagy::Backend

  before_action :set_default_format

  protected

  def paginate_collection(collection, options = {})
    items = options[:per_page] || params[:per_page] || Pagy::DEFAULT[:items]
    items = items.to_i
    if items > Pagy::DEFAULT[:max_per_page]
      raise PaginationError.max_per_page_exceeded(Pagy::DEFAULT[:max_per_page])
    end
    page = options[:page] || params[:page] || Pagy::DEFAULT[:page]
    if page.to_i < 1
      raise PaginationError.invalid_page
    end
    pagy, paginated = pagy(collection, items: items, page: page)
    {
      data: options[:serializer] ? paginated.as_json(options[:serializer]) : paginated,
      meta: {
        page: pagy.page,
        per_page: pagy.vars[:items],
        total_pages: pagy.pages,
        total_count: pagy.count
      }
    }
  end

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
