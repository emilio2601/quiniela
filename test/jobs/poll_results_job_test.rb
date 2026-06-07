require "test_helper"

class PollResultsJobTest < ActiveJob::TestCase
  test "fetches matches, imports results, and records a successful run" do
    kickoff = Time.utc(2030, 6, 11, 19)
    match = Match.create!(number: 911, home_team: "Mexico", away_team: "South Africa", kickoff_at: kickoff)
    payload = [ {
      "id" => 1, "utcDate" => kickoff.iso8601, "status" => "FINISHED", "stage" => "GROUP_STAGE",
      "homeTeam" => { "name" => "Mexico" }, "awayTeam" => { "name" => "South Africa" },
      "score" => { "fullTime" => { "home" => 0, "away" => 1 } }
    } ]

    assert_difference "PollRun.count", 1 do
      PollResultsJob.new.perform(client: Struct.new(:matches).new(payload))
    end

    assert match.reload.finished?
    assert_equal [ 0, 1 ], [ match.home_score, match.away_score ]

    run = PollRun.recent.first
    assert run.ok?
    assert_equal 1, run.scored
  end

  test "a client error is swallowed and recorded as a failed run" do
    failing = Object.new
    def failing.matches = raise(FootballData::Client::Error, "rate limited")

    assert_difference "PollRun.count", 1 do
      assert_nothing_raised { PollResultsJob.new.perform(client: failing) }
    end

    run = PollRun.recent.first
    assert_not run.ok?
    assert_match "rate limited", run.error
  end
end
