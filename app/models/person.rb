class Person < ApplicationRecord
  belongs_to :entity, dependent: :destroy
  
  validates :name, :family_name, :email, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  accepts_nested_attributes_for :entity
end
