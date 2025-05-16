class Company < ApplicationRecord
  belongs_to :entity, dependent: :destroy
  belongs_to :admin, class_name: 'User', optional: true
  belongs_to :parent, class_name: 'Company', optional: true
  
  has_many :subsidiaries, class_name: 'Company', foreign_key: 'parent_id', dependent: :nullify
  
  validates :trader_name, presence: true

  accepts_nested_attributes_for :entity
end
