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
end
