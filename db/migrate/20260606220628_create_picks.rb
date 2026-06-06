class CreatePicks < ActiveRecord::Migration[8.1]
  def change
    create_table :picks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :match, null: false, foreign_key: true
      t.integer :prediction, null: false

      t.timestamps
    end
    add_index :picks, [ :user_id, :match_id ], unique: true
  end
end
