require "test_helper"

class MatchTest < ActiveSupport::TestCase
  test "requires teams and kickoff" do
    assert_not Match.new.valid?
  end

  test "result is nil until both scores are present" do
    match = Match.new(home_team: "A", away_team: "B", kickoff_at: 1.day.from_now)
    assert_nil match.result

    match.home_score = 1
    assert_nil match.result
  end

  test "result is derived from the scores" do
    match = matches(:finished)
    assert_equal :away, match.result

    match.update_columns(home_score: 2, away_score: 1)
    assert_equal :home, match.result

    match.update_columns(home_score: 1, away_score: 1)
    assert_equal :draw, match.result
  end

  test "locked? flips at kickoff" do
    assert matches(:finished).locked?
    assert_not matches(:upcoming).locked?
  end

  test "knockout? is true only beyond the 72-match group stage" do
    assert_not Match.new(number: 72).knockout?
    assert Match.new(number: 73).knockout?
  end

  test "points_breakdown reports the crowd split and award" do
    # fixtures: 3 picked the finished match, only Cara (away) called it right
    assert_equal({ total: 3, correct: 1, beat: 2, award: 2 }, matches(:finished).points_breakdown)
  end

  test "points_breakdown is nil until the match is settled" do
    assert_nil matches(:upcoming).points_breakdown
  end
end
