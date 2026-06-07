class LeaderboardController < ApplicationController
  def index
    @standings = Leaderboard.standings
    @finished_count = Match.finished.count
  end
end
