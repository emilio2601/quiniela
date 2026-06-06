class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.string :home_team, null: false
      t.string :away_team, null: false
      t.datetime :kickoff_at, null: false
      t.integer :home_score
      t.integer :away_score
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end
    add_index :matches, :kickoff_at
    add_index :matches, :status
  end
end
