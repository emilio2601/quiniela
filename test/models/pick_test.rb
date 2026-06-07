require "test_helper"

class PickTest < ActiveSupport::TestCase
  test "can be created on an open match" do
    pick = Pick.new(user: users(:ana), match: matches(:upcoming), prediction: :home)
    assert pick.valid?
  end

  test "rejected once the match has kicked off" do
    pick = Pick.new(user: users(:ben), match: matches(:finished), prediction: :home)
    assert_not pick.valid?
    assert_includes pick.errors[:base], "Picks lock at kickoff and can no longer be changed"
  end

  test "cannot be edited after kickoff" do
    pick = picks(:cara_finished)
    pick.prediction = :home
    assert_not pick.valid?
  end

  test "one pick per user per match" do
    dup = Pick.new(user: users(:cara), match: matches(:finished), prediction: :home)
    assert_not dup.valid?
  end

  test "correct? matches the derived result of a finished match" do
    assert picks(:cara_finished).correct?
    assert_not picks(:ana_finished).correct?
  end

  test "correct? is false while the match is unfinished" do
    pick = Pick.new(user: users(:ana), match: matches(:upcoming), prediction: :home)
    assert_not pick.correct?
  end

  test "draw is not allowed on a knockout match" do
    pick = Pick.new(user: users(:ana), match: matches(:knockout), prediction: :draw)
    assert_not pick.valid?
    assert pick.errors[:prediction].any?
  end

  test "a team pick is allowed on a knockout match" do
    assert Pick.new(user: users(:ana), match: matches(:knockout), prediction: :home).valid?
  end
end
