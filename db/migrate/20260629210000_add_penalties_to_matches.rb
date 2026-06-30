class AddPenaltiesToMatches < ActiveRecord::Migration[8.1]
  def change
    # Shootout tally for a knockout decided on penalties. home_score/away_score
    # hold the level 120-minute score; these hold the penalty score shown beside
    # it (e.g. 1-1 (4-5)). Null for every match not decided on penalties.
    add_column :matches, :home_penalties, :integer
    add_column :matches, :away_penalties, :integer
  end
end
