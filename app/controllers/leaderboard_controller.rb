class LeaderboardController < ApplicationController
  def index
    @standings = Leaderboard.standings
    @finished_count = Match.finished.count
    @complete = @finished_count.positive? && Match.where.not(status: "finished").none?
    @champions = @complete ? leaders : []
  end

  private

  # Everyone tied at the top, since the scoring rule makes a shared title
  # perfectly possible and sort order shouldn't be the thing that breaks it.
  # Empty when nobody has scored, so a pool of zeroes crowns no one.
  def leaders
    top = @standings.first
    return [] unless top && top[:points].positive?

    @standings.take_while { |row| row[:points] == top[:points] }
  end
end
