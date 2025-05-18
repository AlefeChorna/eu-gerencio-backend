require "test_helper"

class AuthHelperTest < ActiveSupport::TestCase
  test "calculate_secret_hash returns correct hash" do
    # This value if fixed in order to validate the correct encryption, so if someone changes the env variables, the test will fail
    expected_hash = "dqnc+gWKmStP3dc0xzQAgtG6B1bdG8A4fhE3s2H4Pwg="
    assert_equal expected_hash, AuthHelper.calculate_secret_hash("valid-username")
  end

  test "calculate_secret_hash returns different hashes for different usernames" do
    hash1 = AuthHelper.calculate_secret_hash("valid-username-1")
    hash2 = AuthHelper.calculate_secret_hash("valid-username-2")
    refute_equal hash1, hash2
  end
end
