class UserCompany < ApplicationRecord
  belongs_to :company
  belongs_to :user
  validates :company_id, uniqueness: { scope: :user_id, message: "is already associated with this user" }
end
