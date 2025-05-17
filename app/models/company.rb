class Company < ApplicationRecord
  belongs_to :entity, dependent: :destroy
  belongs_to :admin, class_name: "User", optional: true
  belongs_to :parent, class_name: "Company", optional: true

  has_many :subsidiaries, class_name: "Company", foreign_key: "parent_id", dependent: :nullify

  validates :trader_name, presence: true
  validate :entity_registration_type_matches
  validate :entity_registration_number

  accepts_nested_attributes_for :entity

  private

  def entity_registration_type_matches
    return if entity.registration_type == "cnpj"
    errors.add(:registration_type, "must be cnpj")
  end

  def entity_registration_number
    return if entity.registration_number.length == 14
    errors.add(:base, "registration_number must be 14 characters")
  end
end
