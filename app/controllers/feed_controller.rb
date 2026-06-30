class FeedController < ApplicationController
  PER_PAGE = 20

  # Every match that's kicked off, freshest first, with all picks revealed —
  # in-progress games (locked, not yet scored) as well as finished ones. Public:
  # picks lock at kickoff, so once a match is locked there's nothing left to
  # hide. Finished matches show the score and points; in-progress ones just
  # show who called what. Paginated since the feed grows to the full bracket.
  def index
    scope = Match.locked.with_known_teams
    @total_pages = [ (scope.count.to_f / PER_PAGE).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @total_pages)

    @matches = scope.includes(picks: :user)
                    .order(kickoff_at: :desc)
                    .offset((@page - 1) * PER_PAGE)
                    .limit(PER_PAGE)
  end
end
