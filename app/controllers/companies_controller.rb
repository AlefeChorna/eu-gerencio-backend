class CompaniesController < ApplicationController
  before_action :authenticate_user!

  def index
    companies = Company
      .joins(:user_companies)
      .where(user_companies: { user_id: current_user.id })

    render json: paginate_collection(
      companies,
      serializer: { include: [ :entity ] }
    )
  end
end
