# A record of one results-poller run, surfaced on the admin job-health panel.
class PollRun < ApplicationRecord
  scope :recent, -> { order(created_at: :desc) }
  # Runs worth looking at: ones that changed or flagged something, or errored.
  # The steady state is a no-op (scored/resolved/unmatched all 0), which we skip.
  scope :notable, -> { where("NOT ok OR scored > 0 OR resolved > 0 OR unmatched > 0") }

  # The schedule the poller runs on (see config/recurring.yml). Used to decide
  # whether the last run is overdue.
  INTERVAL = 30.minutes

  def self.record_success(summary)
    create!(ok: true, scored: summary.scored, resolved: summary.resolved, unmatched: summary.unmatched)
  end

  def self.record_failure(message)
    create!(ok: false, error: message.to_s[0, 500])
  end

  # Healthy if the latest run succeeded and isn't overdue; failing if it
  # errored; stale if nothing has run within a couple of intervals.
  def self.health(now: Time.current)
    last = recent.first
    return :unknown if last.nil?
    return :failing unless last.ok?
    return :stale if last.created_at < now - (INTERVAL * 2)

    :healthy
  end

  def summary
    ok? ? "scored #{scored}, resolved #{resolved}, unmatched #{unmatched}" : (error.presence || "failed")
  end
end
