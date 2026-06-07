require "test_helper"

class FeedPageTest < ActionDispatch::IntegrationTest
  test "is public and reveals every pick on a finished match" do
    get feed_path
    assert_response :success
    assert_select ".ql-feed__item", minimum: 1
    # the finished fixture has 3 picks, only Cara (away) was right
    assert_select ".ql-feed__call", count: 3
    assert_select ".ql-feed__call.is-hit", count: 1
  end

  test "calls out a lone correct caller" do
    get feed_path
    assert_select ".ql-feed__lonecall", /Cara/
  end

  test "does not list unfinished matches" do
    get feed_path
    # only the single finished fixture appears
    assert_select ".ql-feed__item", count: 1
  end

  test "shows an empty state when nothing has finished" do
    matches(:finished).update_columns(status: "scheduled", home_score: nil, away_score: nil)
    get feed_path
    assert_response :success
    assert_select ".ql-blank"
    assert_select ".ql-feed__item", count: 0
  end
end
