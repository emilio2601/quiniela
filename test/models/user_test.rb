require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not User.new.valid?
  end

  test "name is unique regardless of case" do
    assert_not User.new(name: "ANA").valid?
  end
end
