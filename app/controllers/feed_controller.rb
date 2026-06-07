class FeedController < ApplicationController
  # Recent finished matches with every player's pick revealed. Public — picks
  # are already locked (and the match is over), so there's nothing to hide.
  def index
    @matches = Match.finished.with_known_teams
                    .includes(picks: :user)
                    .order(kickoff_at: :desc)
                    .limit(30)
  end
end
