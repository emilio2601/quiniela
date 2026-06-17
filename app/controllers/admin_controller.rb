class AdminController < ApplicationController
  # Internal engagement + operations overview. Public but unlinked (see routes).
  def index
    @players_count = User.count
    @total_picks = Pick.count
    @open_count = Match.pickable.count
    @finished_count = Match.finished.count
    @last_match_update = Match.maximum(:updated_at)

    open_match_ids = Match.pickable.pluck(:id).to_set
    points = Leaderboard.standings.index_by { |row| row[:user].id }

    @rows = User.includes(:picks).map do |user|
      picks = user.picks
      {
        user: user,
        picks: picks.size,
        open_picks: picks.count { |pick| open_match_ids.include?(pick.match_id) },
        points: points.dig(user.id, :points) || 0,
        # updated_at, not created_at — a pick is upserted, so changing your call
        # bumps updated_at; created_at would only show the first pick ever made.
        last_pick_at: picks.map(&:updated_at).max
      }
    end.sort_by { |row| [ -row[:picks], row[:user].name ] }

    # Operations: audit the (eventual) results poller and eyeball the slate.
    @recent_results = Match.finished.includes(:picks).order(updated_at: :desc).limit(20)
    @upcoming = Match.pickable.includes(:picks).order(:kickoff_at).limit(12)

    # Integrity flags — should be empty in a healthy state.
    @awaiting_result = Match.locked.where(status: "scheduled").with_known_teams.order(:kickoff_at)
    @finished_no_score = Match.finished.where("home_score IS NULL OR away_score IS NULL").order(:kickoff_at)

    # Results poller health: the latest run as a heartbeat, plus the runs that
    # actually did something (or errored) — the no-ops are noise.
    @poller_health = PollRun.health
    @last_poll = PollRun.recent.first
    @poll_run_count = PollRun.count
    @notable_runs = PollRun.notable.recent.limit(12)
  end
end
