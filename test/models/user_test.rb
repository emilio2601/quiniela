require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not User.new.valid?
  end

  test "name is unique regardless of case" do
    assert_not User.new(name: "ANA").valid?
  end

  test "identify finds an existing player regardless of case or padding" do
    assert_equal users(:ana), User.identify("  aNa ")
  end

  test "identify does not sign up an unknown name" do
    assert_no_difference -> { User.count } do
      assert_nil User.identify("Newcomer")
    end
  end

  test "identify handles a blank name" do
    assert_nil User.identify("")
    assert_nil User.identify(nil)
  end
end
