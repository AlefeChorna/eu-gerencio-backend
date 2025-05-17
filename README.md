# EuGerencio Backend

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Creating a Company with an Entity
company = Company.create!(
  trader_name: "Acme Subsidiary",
  entity_attributes: {
    registration_number: "00000000000191",
    registration_type: "cnpj"
  }
)

# Creating a Person with an Entity
person = Person.create!(
  name: "John",
  family_name: "Doe",
  email: "john.doe@example.com",
  entity_attributes: {
    registration_number: "123456789",
    registration_type: "cpf"
  }
)

# Creating a User with an Entity
user = User.create!(
  entity_attributes: {
    registration_number: "987654321",
    registration_type: "cpf"
  }
)

# Users Service create user

UsersService.create({
  email: "jhon.doe@example.com",
  first_name: "John",
  last_name: "Doe",
  company_id: company.id
})
