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

  test "does not list matches that haven't kicked off" do
    get feed_path
    # the upcoming + knockout fixtures are in the future; only the locked
    # finished fixture appears
    assert_select ".ql-feed__item", count: 1
  end

  test "lists a locked match that isn't finished, with picks revealed but no score" do
    # same fixture, but kicked off (2h ago) and not yet scored
    matches(:finished).update_columns(status: "scheduled", home_score: nil, away_score: nil)
    get feed_path
    assert_response :success
    assert_select ".ql-feed__item", count: 1
    assert_select ".ql-feed__live", /in progress/i      # the in-progress tag
    assert_select ".ql-feed__nums", count: 0            # no score shown yet
    assert_select ".ql-feed__call", count: 3            # all three calls revealed
    assert_select ".ql-feed__call.is-hit", count: 0     # nothing scored yet
  end

  test "shows an empty state when nothing has kicked off" do
    matches(:finished).update_columns(status: "scheduled", home_score: nil, away_score: nil,
                                       kickoff_at: 2.days.from_now)
    get feed_path
    assert_response :success
    assert_select ".ql-blank"
    assert_select ".ql-feed__item", count: 0
  end
end
