require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  test "is publicly reachable without signing in" do
    get admin_path
    assert_response :success
  end

  test "lists players with their pick counts" do
    get admin_path
    assert_select ".ql-stat__n" # the headline stat cards
    # fixtures define three players, each with one pick on the finished match
    assert_select ".ql-table--players .player", count: User.count
    assert_select ".ql-table--players tbody tr", count: User.count
  end

  test "shows the results audit and upcoming sections" do
    get admin_path
    assert_select ".ql-table--results" # the finished fixture appears here
    assert_select ".ql-table--upcoming"
  end
end
