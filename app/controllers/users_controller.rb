class UsersController < ApplicationController
  before_action :authenticate_user!

  def me
    user = current_user.as_json.merge(
      companies: current_user.companies.as_json(
        include: {
          entity: {},
          subsidiaries: { include: :entity }
        }
      )
    )
    render json: user, status: :ok
  end
end
