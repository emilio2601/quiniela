class AddNumberToMatches < ActiveRecord::Migration[8.1]
  def change
    # openfootball's 1..104 match slot. Stable identity for a fixture even
    # before its teams are known (knockout placeholders like W97 reference it),
    # so the results poller can resolve teams/scores without team-name churn.
    add_column :matches, :number, :integer, null: false
    add_index :matches, :number, unique: true
  end
end
