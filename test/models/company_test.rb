require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  test 'should not save company without trader_name' do
    company = Company.new({
        entity_attributes: {
            registration_type: 'cnpj',
            registration_number: '12345678901234'
        }
    })
    assert_not company.save, 'Saved the company without a trader_name'
  end

  test 'should validate trader_name presence' do
    company = Company.new({
        trader_name: '',
        entity_attributes: {
            registration_type: 'cnpj',
            registration_number: '12345678901234'
        }
    })
    assert_not company.valid?
    assert_includes company.errors[:trader_name], "can't be blank"
  end

  test 'should validate entity registration type' do
    company = Company.new({
        trader_name: 'Test Company',
        entity_attributes: {
            registration_type: '',
            registration_number: '12345678901234'
        }
    })
    assert_not company.valid?
    assert_includes company.errors[:registration_type], 'must be cnpj'

    company.entity.registration_type = 'cnpj'
    assert company.valid?
  end

  test 'should validate entity registration number length' do
    company = Company.new({
        trader_name: 'Test Company',
        entity_attributes: {
            registration_type: 'cnpj',
            registration_number: '1234567890123' # 13 chars
        }
    })
    assert_not company.valid?
    assert_includes company.errors[:base], 'registration_number must be 14 characters'

    company.entity.registration_number = '12345678901234' # 14 chars
    assert company.valid?
  end

  test 'should accept valid company with all required attributes' do
    company = Company.new(
      trader_name: 'Test Company',
      entity_attributes: {
        registration_type: 'cnpj',
        registration_number: '12345678901234'
      }
    )
    assert company.valid?
  end
end
