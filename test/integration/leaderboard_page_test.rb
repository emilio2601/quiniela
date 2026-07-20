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

  # Fixtures leave `upcoming` and `knockout` unplayed, so the board is still live.
  test "does not crown anyone while matches are outstanding" do
    get leaderboard_path
    assert_select ".ql-champ", count: 0
    assert_select ".ql-picks__title", text: /field/
  end

  test "crowns the champion once every match is settled" do
    Match.update_all(status: "finished")
    get leaderboard_path
    assert_select ".ql-champ__label", text: "Champion"
    assert_select ".ql-champ__who", text: "Cara"
    assert_select ".ql-picks__title", text: /final/i
  end

  test "a tie at the top is a shared title, not an arbitrary winner" do
    Match.update_all(status: "finished")
    # Ben joins Cara on the upset, so both beat one player for 1 point each.
    picks(:ben_finished).update_column(:prediction, 2)
    get leaderboard_path
    assert_select ".ql-champ__label", text: "Joint champions"
    assert_select ".ql-champ__who", text: /Ben and Cara/
    assert_select ".ql-board__row.lead", count: 2
  end

  test "crowns no one when nobody scored" do
    Match.update_all(status: "finished")
    Pick.delete_all
    get leaderboard_path
    assert_response :success
    assert_select ".ql-champ", count: 0
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
