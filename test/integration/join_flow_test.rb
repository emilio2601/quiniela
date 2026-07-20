require "test_helper"

class JoinFlowTest < ActionDispatch::IntegrationTest
  test "an existing player signs in by name, any case" do
    assert_no_difference "User.count" do
      post join_path, params: { name: "ANA" }
    end
    assert_redirected_to picks_path
    assert_equal users(:ana).id, session[:user_id]

    follow_redirect!
    assert_select ".ql-top__who", /Ana/
  end

  # The pool closed with the tournament: an unknown name is turned away rather
  # than signed up as a new player.
  test "an unknown name is turned away, not signed up" do
    assert_no_difference "User.count" do
      post join_path, params: { name: "Nadia" }
    end
    assert_redirected_to root_path
    assert_nil session[:user_id]
    assert_match(/pool is closed/, flash[:alert])
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
    post join_path, params: { name: "Ana" }
    assert session[:user_id]

    delete leave_path
    assert_nil session[:user_id]
  end
end
