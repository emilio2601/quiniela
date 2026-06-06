require "test_helper"

class JoinFlowTest < ActionDispatch::IntegrationTest
  test "joining by a new name creates a user and signs in" do
    assert_difference "User.count", 1 do
      post join_path, params: { name: "Nadia" }
    end
    assert_redirected_to root_path
    assert_equal User.find_by(name: "Nadia").id, session[:user_id]

    follow_redirect!
    assert_select ".ql-claimed__hi", /Nadia/
  end

  test "joining with an existing name (any case) reuses the player" do
    assert_no_difference "User.count" do
      post join_path, params: { name: "ANA" }
    end
    assert_equal users(:ana).id, session[:user_id]
  end

  test "a blank name is rejected and the form stays" do
    assert_no_difference "User.count" do
      post join_path, params: { name: "   " }
    end
    assert_redirected_to root_path

    follow_redirect!
    assert_select ".ql-coupon__label"
  end

  test "leaving clears the session" do
    post join_path, params: { name: "Nadia" }
    assert session[:user_id]

    delete leave_path
    assert_nil session[:user_id]
  end
end
