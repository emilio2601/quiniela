class AddOutcomeToMatches < ActiveRecord::Migration[8.1]
  def change
    # The authoritative result from football-data's score.winner (home/draw/away).
    # Needed because a knockout decided on penalties has a level full-time score
    # but a real winner — equal scores don't mean a draw there.
    add_column :matches, :outcome, :string
  end
end
