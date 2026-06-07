class AddExternalIdToMatches < ActiveRecord::Migration[8.1]
  def change
    # football-data.org's match id, stored once a fixture is matched so later
    # polls map straight to the row regardless of team-name resolution.
    add_column :matches, :external_id, :bigint
    add_index :matches, :external_id, unique: true
  end
end
