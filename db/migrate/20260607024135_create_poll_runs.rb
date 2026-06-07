class CreatePollRuns < ActiveRecord::Migration[8.1]
  def change
    # One row per results-poller run, for the admin job-health panel.
    create_table :poll_runs do |t|
      t.boolean :ok, null: false, default: true
      t.integer :scored
      t.integer :resolved
      t.integer :unmatched
      t.string :error

      t.timestamps
    end
    add_index :poll_runs, :created_at
  end
end
