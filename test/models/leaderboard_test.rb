require "test_helper"

class LeaderboardTest < ActiveSupport::TestCase
  test "a correct pick scores the number of people it beat" do
    # Finished match: 3 picked, 1 correct (Cara). She beat 2 -> 2 points.
    standings = Leaderboard.standings.index_by { |row| row[:user] }

    assert_equal 2, standings[users(:cara)][:points]
    assert_equal 0, standings[users(:ana)][:points]
    assert_equal 0, standings[users(:ben)][:points]
  end

  test "sorted by points desc then name, everyone included" do
    names = Leaderboard.standings.map { |row| row[:user].name }
    assert_equal %w[Cara Ana Ben], names
  end

  test "points_for_correct is the count of people beaten" do
    assert_equal 4, Leaderboard.points_for_correct(total_picks: 6, correct_picks: 2)
  end
end
