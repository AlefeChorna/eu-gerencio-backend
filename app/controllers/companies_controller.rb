class CompaniesController < ApplicationController
  before_action :authenticate_user!

  def index
    companies = if current_user.is_root
      Company.all
    else
      Company
        .joins(:user_companies)
        .where(user_companies: { user_id: current_user.id })
    end

    companies = companies.order(id: :desc)
    subsidiaries = if current_user.is_root
      { subsidiaries: { include: :entity } }
    else
      {}
    end

    render json: paginate_collection(
      companies,
      serializer: {
        include: {
          entity: {},
          **subsidiaries
        }
      }
    )
  end
end
