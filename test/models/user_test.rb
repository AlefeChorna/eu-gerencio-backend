require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @company = Company.create!({
        trader_name: "Test Company",
        entity_attributes: {
            registration_number: "12345678901234",
            registration_type: "cnpj"
        }
    })
    @user = User.create!({
      email: "test@example.com",
      first_name: "John",
      last_name: "Doe",
      company_id: @company.id
    })
  end

  test "should be valid with all required fields" do
    assert @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "email should be valid format" do
    valid_emails = %w[
      user@example.com
      USER@foo.COM
      A_US-ER@foo.bar.org
      first.last@foo.jp
      alice+bob@baz.cn
    ]

    valid_emails.each do |valid_email|
      @user.email = valid_email
      assert @user.valid?, "#{valid_email} should be valid"
    end
  end

  test "email should reject invalid formats" do
    invalid_emails = %w[
      user@example,com
      user_at_foo.org
      user.name@example.
      foo@bar_baz.com
      foo@bar+baz.com
    ]

    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email} should be invalid"
      assert_includes @user.errors[:email], "is invalid"
    end
  end

  test "first_name should be present" do
    @user.first_name = ""
    assert_not @user.valid?
    assert_includes @user.errors[:first_name], "can't be blank"
  end

  test "last_name should be present" do
    @user.last_name = ""
    assert_not @user.valid?
    assert_includes @user.errors[:last_name], "can't be blank"
  end

  test "should belong to a company" do
    assert_respond_to @user, :company
    assert_respond_to @user, :company=
    assert_not_nil @user.company
  end
end
