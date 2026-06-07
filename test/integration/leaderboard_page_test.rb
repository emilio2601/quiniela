require "test_helper"

class LeaderboardPageTest < ActionDispatch::IntegrationTest
  test "is publicly reachable and ranks every player" do
    get leaderboard_path
    assert_response :success
    assert_select ".ql-board__row", count: User.count
  end

  test "leads with the top scorer" do
    # fixtures: Cara called the away upset on the finished match (beats 2 -> 2 pts)
    get leaderboard_path
    assert_select ".ql-board__row.lead .ql-board__name", text: "Cara"
  end

  test "shows an empty state when no one has joined" do
    Pick.delete_all
    User.delete_all
    get leaderboard_path
    assert_response :success
    assert_select ".ql-blank"
    assert_select ".ql-board", count: 0
  end
end
