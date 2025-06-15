class CompaniesController < ApplicationController
  before_action :authenticate_user!

  def index
    companies = Company.where(id: current_user.company_id)

    render json: paginate_collection(
      companies,
      serializer: { include: [ :entity ] }
    )
  end
end
