class PicksController < ApplicationController
  before_action :require_player

  # The board: pickable matches to call, plus everything already locked.
  def index
    @open_matches = Match.pickable.order(:kickoff_at)
    @settled_matches = Match.locked.with_known_teams.order(kickoff_at: :desc)
    @picks_by_match = current_user.picks.index_by(&:match_id)
  end

  # Upsert this player's prediction for one match (instant, per-match save).
  # The model rejects picks once the match has kicked off.
  def create
    @match = Match.find(params[:match_id])
    pick = current_user.picks.find_or_initialize_by(match: @match)
    pick.update(prediction: params[:prediction])

    # Re-read so the frame reflects what's actually stored (a rejected late
    # pick leaves the previously saved value, or none).
    @pick = current_user.picks.find_by(match: @match)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@match, :pick),
          partial: "picks/controls",
          locals: { match: @match, pick: @pick }
        )
      end
      format.html { redirect_to picks_path }
    end
  end
end
