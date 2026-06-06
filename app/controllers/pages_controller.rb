class PagesController < ApplicationController
  def home
    @upcoming_matches = Match.open_for_picks.order(:kickoff_at).limit(3)
  end
end
