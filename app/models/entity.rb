class Entity < ApplicationRecord
  belongs_to :entityable, polymorphic: true, dependent: :destroy, optional: true
  
  validates :registration_number, presence: true, uniqueness: { scope: :registration_type }
  validates :registration_type, presence: true
end
