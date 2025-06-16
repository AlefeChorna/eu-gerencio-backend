class User < ApplicationRecord
  has_many :user_companies, dependent: :destroy
  has_many :companies, through: :user_companies

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
end
