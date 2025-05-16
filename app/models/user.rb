class User < ApplicationRecord
  belongs_to :entity, dependent: :destroy
  has_many :administered_companies, class_name: 'Company', foreign_key: 'admin_id', dependent: :nullify
  accepts_nested_attributes_for :entity
end
