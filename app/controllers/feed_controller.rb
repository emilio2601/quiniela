class FeedController < ApplicationController
  # Every match that's kicked off, freshest first, with all picks revealed —
  # in-progress games (locked, not yet scored) as well as finished ones. Public:
  # picks lock at kickoff, so once a match is locked there's nothing left to
  # hide. Finished matches show the score and points; in-progress ones just
  # show who called what.
  def index
    @matches = Match.locked.with_known_teams
                    .includes(picks: :user)
                    .order(kickoff_at: :desc)
                    .limit(30)
  end
end
