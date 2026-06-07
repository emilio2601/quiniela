require "test_helper"

class PollRunTest < ActiveSupport::TestCase
  test "health is unknown with no runs" do
    assert_equal :unknown, PollRun.health
  end

  test "health is healthy after a recent successful run" do
    PollRun.create!(ok: true, scored: 0, resolved: 0, unmatched: 0)
    assert_equal :healthy, PollRun.health
  end

  test "health is failing when the latest run errored" do
    PollRun.create!(ok: true, scored: 1, resolved: 0, unmatched: 0, created_at: 1.hour.ago)
    PollRun.create!(ok: false, error: "boom")
    assert_equal :failing, PollRun.health
  end

  test "health is stale when the latest run is overdue" do
    PollRun.create!(ok: true, scored: 0, resolved: 0, unmatched: 0, created_at: 3.hours.ago)
    assert_equal :stale, PollRun.health
  end

  test "notable excludes clean no-ops but keeps changes and errors" do
    noop = PollRun.create!(ok: true, scored: 0, resolved: 0, unmatched: 0)
    scored = PollRun.create!(ok: true, scored: 3, resolved: 0, unmatched: 0)
    unmatched = PollRun.create!(ok: true, scored: 0, resolved: 0, unmatched: 2)
    failed = PollRun.create!(ok: false, error: "boom")

    notable = PollRun.notable
    assert_includes notable, scored
    assert_includes notable, unmatched
    assert_includes notable, failed
    assert_not_includes notable, noop
  end
end
